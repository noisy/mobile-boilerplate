"""Tests for firebase_defines.py, run by CI: python3 -m unittest discover -s scripts"""

import shutil
import tempfile
import unittest
from pathlib import Path

import firebase_defines

ROOT = Path(__file__).resolve().parent.parent


class FirebaseDefinesTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        shutil.copy(ROOT / "app.env", self.root / "app.env")
        (self.root / "firebase").mkdir()

    def use_template(self, template, name):
        shutil.copy(ROOT / "firebase" / template, self.root / "firebase" / name)

    def test_no_files_means_demo_mode(self):
        self.assertEqual(firebase_defines.collect(self.root), {})

    def test_reads_both_platforms(self):
        self.use_template("google-services.template.json", "google-services.json")
        self.use_template("GoogleService-Info.template.plist", "GoogleService-Info.plist")
        defines = firebase_defines.collect(self.root)
        self.assertTrue(defines["FIREBASE_ANDROID_APP_ID"].startswith("1:"))
        self.assertTrue(defines["FIREBASE_IOS_APP_ID"].startswith("1:"))
        self.assertIn("webclientid", defines["GOOGLE_SERVER_CLIENT_ID"])
        self.assertTrue(
            defines["GOOGLE_IOS_REVERSED_CLIENT_ID"].startswith("com.googleusercontent.apps.")
        )

    def test_rejects_a_file_from_another_project(self):
        env = self.root / "app.env"
        env.write_text(
            "\n".join(
                'FIREBASE_PROJECT="some-other-project"' if line.startswith("FIREBASE_PROJECT=") else line
                for line in env.read_text().splitlines()
            )
        )
        self.use_template("google-services.template.json", "google-services.json")
        with self.assertRaises(firebase_defines.ConfigError):
            firebase_defines.collect(self.root)

    def test_rejects_a_file_without_this_android_app(self):
        env = self.root / "app.env"
        env.write_text(
            "\n".join(
                'APP_ID="org.other.app"' if line.startswith("APP_ID=") else line
                for line in env.read_text().splitlines()
            )
        )
        self.use_template("google-services.template.json", "google-services.json")
        with self.assertRaises(firebase_defines.ConfigError):
            firebase_defines.collect(self.root)


if __name__ == "__main__":
    unittest.main()
