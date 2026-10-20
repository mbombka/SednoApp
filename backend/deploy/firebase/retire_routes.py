"""Keep only the checked live Hosting tag; never silently preserve old API URLs."""
import argparse
import json
import subprocess
import time
import urllib.error
import urllib.request


def output(args):
    return json.loads(subprocess.check_output(args, text=True))


def deployment_manifest(manifest, services):
    if len(services) > 1:
        raise ValueError('Niejednoznaczna usługa Cloud Run.')
    current = services[0]['status']['traffic'] if services else []
    manifest['spec']['traffic'] = [{'latestRevision': True, 'percent': 100}] + [
        {'revisionName': t['revisionName'], 'tag': t['tag']} for t in current if 'tag' in t]
    return manifest


def plan(service, channels, revision, region):
    status = service['status']
    if status['latestReadyRevisionName'] != revision or status['latestCreatedRevisionName'] != revision:
        raise ValueError('Rewizja zmieniła się podczas wdrożenia.')
    traffic = status['traffic']
    if sum(t.get('percent', 0) for t in traffic if t['revisionName'] == revision) != 100:
        raise ValueError('Bieżąca rewizja nie otrzymuje 100% ruchu.')
    live = next(c for c in channels if c['name'].endswith('/channels/live'))
    rewrites = live['release']['version']['config']['rewrites']
    runs = [r['run'] for r in rewrites if 'run' in r]
    if not runs or any(r.get('serviceId') != 'sedno-api' or r.get('region') != region or not r.get('tag') for r in runs):
        raise ValueError('Hosting nie ma oczekiwanego przypięcia API.')
    keep = {r['tag'] for r in runs}
    tags = {t['tag']: t for t in traffic if 'tag' in t}
    if any(tag not in tags or tags[tag]['revisionName'] != revision for tag in keep):
        raise ValueError('Hosting wskazuje inną rewizję; przerwano bez usuwania tagów.')
    return [t for tag, t in tags.items() if tag not in keep]


def http_status(url):
    try:
        with urllib.request.urlopen(url, timeout=20) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare-service')
    parser.add_argument('--current-services')
    for name in ('project', 'region', 'site', 'revision'):
        parser.add_argument('--' + name)
    args = parser.parse_args()
    if args.prepare_service:
        with open(args.prepare_service) as manifest, open(args.current_services) as current:
            print(json.dumps(deployment_manifest(json.load(manifest), json.load(current))))
        return
    if not all((args.project, args.region, args.site, args.revision)):
        parser.error('Wymagane: --project, --region, --site, --revision.')
    cloud = ['gcloud', 'run', 'services']
    scope = ['--project', args.project, '--region', args.region]
    def service():
        return output(cloud + ['describe', 'sedno-api', '--format=json'] + scope)
    def channels():
        result = output(['firebase', 'hosting:channel:list', '--site', args.site, '--project', args.project, '--json'])
        if result.get('status') != 'success':
            raise ValueError('Nie odczytano kanałów Hosting.')
        return result['result']['channels']
    stale = plan(service(), channels(), args.revision, args.region)
    # Only mutate after validating the public Hosting route.
    health = 'https://' + args.site + '.web.app/health/ready'
    if http_status(health) != 200:
        raise ValueError('Hosting nie jest gotowy; przerwano bez usuwania tagów.')
    if stale:
        subprocess.run(cloud + ['update-traffic', 'sedno-api', '--remove-tags',
                       ','.join(t['tag'] for t in stale), '--quiet'] + scope, check=True)
    if plan(service(), channels(), args.revision, args.region):
        raise ValueError('Pozostały nieoczekiwane tagi; sprawdź równoległe wdrożenie.')
    for route in stale:
        # Cloud Run route removal propagates asynchronously. Errors remain fatal.
        for attempt in range(12):
            code = http_status(route['url'] + '/health/ready')
            if code == 404:
                break
            time.sleep(5)
        if code != 404:
            raise ValueError('Stary adres nadal odpowiada: ' + route['url'])
        print(json.dumps({'revision': route['revisionName'], 'url': route['url'], 'status': code}))
    if http_status(health) != 200:
        raise ValueError('Kontrola Hosting po usunięciu tagów nie powiodła się.')
    print(json.dumps({'revision': args.revision, 'hosting': health, 'status': 200}))


if __name__ == '__main__':
    main()
