"""Verify a backend image against disposable Firestore and its production emulator guard."""
import argparse
import json
import subprocess
import time
import uuid
import urllib.error
import urllib.request

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--image', default='sedno-api:local')
image = parser.parse_args().image
suffix = uuid.uuid4().hex[:10]
network = 'sedno-smoke-' + suffix
database = network + '-db'
api = network + '-api'


def docker(*args, check=True):
    return subprocess.run(['docker', *args], check=check, capture_output=True, text=True)


def environment(values):
    return [argument for key, value in values.items() for argument in ('-e', f'{key}={value}')]


try:
    docker('network', 'create', network)
    docker('run', '-d', '--name', database, '--network', network,
           'gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators',
           'gcloud', 'emulators', 'firestore', 'start', '--host-port=0.0.0.0:8080', '--quiet')
    env = {
        'ASPNETCORE_ENVIRONMENT': 'Development', 'ASPNETCORE_HTTP_PORTS': '9090',
        'Firestore__ProjectId': 'demo-synthetic-smoke', 'Firestore__UseEmulator': 'true',
        'FIRESTORE_EMULATOR_HOST': f'{database}:8080',
        'Model__Provider': 'mock', 'PlayIntegrity__Provider': 'mock',
        'Security__CredentialKey': 'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=',
        'Security__FingerprintKey': 'AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI=',
        'Billing__Enabled': 'false',
    }
    docker('run', '-d', '--name', api, '--network', network, '-p', '127.0.0.1::9090',
           *environment(env), image)
    port = docker('port', api, '9090/tcp').stdout.strip().rsplit(':', 1)[1]
    base = f'http://127.0.0.1:{port}'
    for _ in range(60):
        try:
            with urllib.request.urlopen(base + '/health/ready', timeout=2) as response:
                assert response.status == 200
                break
        except (urllib.error.URLError, ConnectionError):
            time.sleep(0.5)
    else:
        raise RuntimeError('Brak gotowości API z lokalnym emulatorem.')
    for path in ['/health/live', '/health/ready', '/prywatnosc', '/usun-konto', '/v1/quota']:
        try:
            response = urllib.request.urlopen(base + path, timeout=5)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            assert response.status == (401 if path == '/v1/quota' else 200), path
            assert 'no-store' in response.headers['Cache-Control'].split(', '), path
    guest_request = urllib.request.Request(base + '/v1/guest-sessions',
        data=json.dumps({'installationId': 'synthetic-installation'}).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(guest_request, timeout=10) as response:
        token = json.load(response)['accessToken']
    request = urllib.request.Request(base + '/v1/simplifications',
        data=json.dumps({'requestId': 'smoke', 'text': 'Sztuczny tekst testowy.'}).encode(),
        headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token})
    with urllib.request.urlopen(request, timeout=10) as response:
        assert json.load(response)['quota']['remaining'] == 4
    cleanup_env = {key: value for key, value in env.items()
                   if key in ('ASPNETCORE_ENVIRONMENT', 'Firestore__ProjectId', 'Firestore__UseEmulator', 'FIRESTORE_EMULATOR_HOST')}
    docker('run', '--rm', '--network', network, *environment(cleanup_env), image, '--cleanup')
    print('Firestore: gotowość, sesja, uproszczenie mock, limit i cleanup bez sekretów: OK.')
    production = dict(cleanup_env, ASPNETCORE_ENVIRONMENT='Production', K_SERVICE='sedno-smoke', PORT='9090')
    rejected = docker('run', '--rm', '--network', network, *environment(production), image, check=False)
    assert rejected.returncode != 0
    assert 'Development-only' in rejected.stdout + rejected.stderr
    print('Produkcja odrzuca emulator: OK.')
    user = docker('image', 'inspect', image, '--format', '{{.Config.User}}').stdout.strip()
    assert user not in ('', '0', 'root')
    print('Użytkownik kontenera:', user)
finally:
    for name in (api, database):
        docker('rm', '-f', name, check=False)
    docker('network', 'rm', network, check=False)
