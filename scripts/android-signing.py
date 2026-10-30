"""Create and reuse the project's private APK signing identity."""
import os
import secrets
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
folder = ROOT / ".tools/signing"
folder.mkdir(parents=True, exist_ok=True)
keystore = folder / "cf-link.jks"
password_file = folder / "password.txt"
if keystore.exists() and not password_file.exists():
    raise RuntimeError("The existing keystore requires its original password file")
if not password_file.exists():
    password_file.write_text(secrets.token_urlsafe(32), encoding="utf-8")
password = password_file.read_text(encoding="utf-8").strip()
if not keystore.exists():
    environment = os.environ.copy()
    environment["TASK_ANDROID_SIGNING_PASSWORD"] = password
    subprocess.run([
        str(Path(environment["JAVA_HOME"]) / "bin/keytool.exe"),
        "-genkeypair", "-storetype", "JKS", "-keyalg", "RSA", "-keysize", "3072",
        "-validity", "10000", "-alias", "cf-link", "-keystore", str(keystore),
        "-storepass:env", "TASK_ANDROID_SIGNING_PASSWORD", "-keypass:env", "TASK_ANDROID_SIGNING_PASSWORD",
        "-dname", "CN=FR CODE LABS, O=FR CODE LABS, C=BR",
    ], env=environment, check=True)
properties = ROOT / "upstream/flutter/android/key.properties"
properties.write_text(
    f"storePassword={password}\nkeyPassword={password}\nkeyAlias=cf-link\nstoreFile={keystore.as_posix()}\n",
    encoding="utf-8",
)
print("APK signing identity ready in .tools/signing; private files excluded from source packages.")
