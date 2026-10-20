import copy
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('retire_routes', Path(__file__).resolve().parents[2] / 'backend/deploy/firebase/retire_routes.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class RetireRoutesTests(unittest.TestCase):
    def setUp(self):
        self.service = {'status': {'latestReadyRevisionName': 'new', 'latestCreatedRevisionName': 'new', 'traffic': [
            {'revisionName': 'new', 'percent': 100, 'tag': 'live', 'url': 'https://live.invalid'},
            {'revisionName': 'old', 'tag': 'old-pin', 'url': 'https://old.invalid'},
            {'revisionName': 'new', 'tag': 'old-release', 'url': 'https://previous.invalid'}]}}
        self.channels = [{'name': 'sites/api/channels/live', 'release': {'version': {'config': {'rewrites': [
            {'run': {'serviceId': 'sedno-api', 'region': 'europe-central2', 'tag': 'live'}}]}}}}]

    def plan(self):
        return MODULE.plan(self.service, self.channels, 'new', 'europe-central2')

    def test_local_export_cannot_resurrect_removed_tags(self):
        manifest = {'spec': {'traffic': [{'revisionName': 'unsafe', 'tag': 'removed'}]}}
        current = copy.deepcopy(self.service)
        current['status']['traffic'] = current['status']['traffic'][:1]
        result = MODULE.deployment_manifest(manifest, [current])
        self.assertEqual([{'latestRevision': True, 'percent': 100}, {'revisionName': 'new', 'tag': 'live'}], result['spec']['traffic'])
        self.assertEqual([{'latestRevision': True, 'percent': 100}], MODULE.deployment_manifest(manifest, [])['spec']['traffic'])

    def test_removes_old_revisions_and_unused_tags_but_preserves_live_pin(self):
        self.assertEqual(['old-pin', 'old-release'], [t['tag'] for t in self.plan()])

    def test_idempotent_when_only_live_pin_remains(self):
        self.service['status']['traffic'] = self.service['status']['traffic'][:1]
        self.assertEqual([], self.plan())

    def test_rejects_stale_or_unknown_hosting_pin(self):
        for tag in ('old-pin', 'unknown'):
            with self.subTest(tag=tag):
                self.channels[0]['release']['version']['config']['rewrites'][0]['run']['tag'] = tag
                with self.assertRaises(ValueError):
                    self.plan()

    def test_rejects_unready_concurrent_or_partial_deployment(self):
        original = copy.deepcopy(self.service)
        for field in ('latestReadyRevisionName', 'latestCreatedRevisionName'):
            self.service = copy.deepcopy(original)
            self.service['status'][field] = 'other'
            with self.assertRaises(ValueError):
                self.plan()
        self.service = original
        self.service['status']['traffic'][0]['percent'] = 50
        with self.assertRaises(ValueError):
            self.plan()

    def test_does_not_mutate_when_hosting_health_fails(self):
        with patch('sys.argv', ['retire_routes.py', '--project', 'test', '--region', 'europe-central2', '--site', 'api', '--revision', 'new']), \
             patch.object(MODULE, 'output', side_effect=[self.service, {'status': 'success', 'result': {'channels': self.channels}}]), \
             patch.object(MODULE, 'http_status', return_value=503), \
             patch.object(MODULE.subprocess, 'run') as mutate:
            with self.assertRaises(ValueError):
                MODULE.main()
            mutate.assert_not_called()

    def test_rejects_foreign_service_or_region(self):
        run = self.channels[0]['release']['version']['config']['rewrites'][0]['run']
        for field in ('serviceId', 'region'):
            original = run[field]
            run[field] = 'other'
            with self.assertRaises(ValueError):
                self.plan()
            run[field] = original
