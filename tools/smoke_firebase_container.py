"""Test a production Cloud Run image using disposable local PostgreSQL containers."""
import argparse
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

try:
    docker('network', 'create', network)
    docker('run', '-d', '--name', database, '--network', network,
           '-e', 'POSTGRES_DB=sedno', '-e', 'POSTGRES_USER=sedno',
           '-e', 'POSTGRES_PASSWORD=synthetic-smoke-password', 'postgres:17-alpine')
    for _ in range(30):
        if docker('exec', database, 'pg_isready', '-U', 'sedno', check=False).returncode == 0:
            break
        time.sleep(0.5)
    connection = f'Host={database};Database=sedno;Username=sedno;Password=synthetic-smoke-password'
    docker('run', '--rm', '--network', network, '-e', 'ConnectionStrings__Postgres=' + connection,
           image, '--migrate')
    print('Migracja kontenera: OK, bez konfiguracji modelu.')
    env = {
        'ConnectionStrings__Postgres': connection, 'K_SERVICE': 'sedno-smoke', 'PORT': '9090',
        'Firebase__ProjectId': 'synthetic-smoke', 'Firebase__DeletionServiceAccountJsonPath': '/unused.json',
        'PlayIntegrity__ServiceAccountJsonPath': '/unused.json', 'OpenAI__ApiKey': 'synthetic-smoke-key',
        'Security__CredentialKey': 'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=',
        'Security__FingerprintKey': 'AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI=',
        'Billing__Enabled': 'false',
    }
    options = []
    for key, value in env.items(): options += ['-e', f'{key}={value}']
    docker('run', '-d', '--name', api, '--network', network, '-p', '127.0.0.1::9090', *options, image)
    port = docker('port', api, '9090/tcp').stdout.strip().rsplit(':', 1)[1]
    base = f'http://127.0.0.1:{port}'
    for _ in range(40):
        try:
            with urllib.request.urlopen(base + '/health/ready', timeout=2) as response:
                assert response.status == 200
                break
        except (urllib.error.URLError, ConnectionError): time.sleep(0.5)
    else: raise RuntimeError('Brak gotowości API.')
    for path in ['/health/live', '/health/ready', '/prywatnosc', '/usun-konto', '/v1/quota']:
        try: response = urllib.request.urlopen(base + path, timeout=5)
        except urllib.error.HTTPError as error: response = error
        with response:
            assert response.status == (401 if path == '/v1/quota' else 200), path
            assert 'no-store' in response.headers['Cache-Control'].split(', '), path
    print('Produkcja Cloud Run: port 9090, probes, dokumenty, 401 bez sesji, no-store: OK.')
    user = docker('image', 'inspect', image, '--format', '{{.Config.User}}').stdout.strip()
    assert user not in ('', '0', 'root')
    print('Użytkownik kontenera:', user)
finally:
    for name in (api, database): docker('rm', '-f', name, check=False)
    docker('network', 'rm', network, check=False)
