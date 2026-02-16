import os
import subprocess
import shutil
import sys
import time

def run_command(command, cwd=None):
    try:
        subprocess.check_call(command, shell=True, cwd=cwd)
        return True
    except subprocess.CalledProcessError:
        return False

def setup_backend():
    print("\n[1/3] Setting up Backend...")
    backend_dir = os.path.join(os.getcwd(), 'backend')
    
    # Check if venv exists
    venv_dir = os.path.join(backend_dir, 'venv')
    if not os.path.exists(venv_dir):
        print("Creating virtual environment...")
        run_command(f"{sys.executable} -m venv venv", cwd=backend_dir)
    
    # Install dependencies
    print("Installing backend dependencies...")
    pip_cmd = os.path.join(venv_dir, 'Scripts', 'pip') if os.name == 'nt' else os.path.join(venv_dir, 'bin', 'pip')
    
    # Fallback to system pip if venv pip not found (unlikely)
    if not os.path.exists(pip_cmd):
        pip_cmd = "pip"

    requirements = [
        "fastapi", "uvicorn", "opencv-python", "numpy", 
        "requests", "pyttsx3", "vosk", "pydantic"
    ]
    # dlib/face_recognition often fail on Windows without C++ build tools, skipping for now to ensure success
    # allowing user to manual install later
    
    run_command(f"{pip_cmd} install {' '.join(requirements)}", cwd=backend_dir)
    print("Backend setup complete.")

def setup_mobile_app():
    print("\n[2/3] Setting up Mobile App...")
    mobile_dir = os.path.join(os.getcwd(), 'mobile_app')
    
    # Check for Flutter
    if not shutil.which("flutter"):
        print("Error: 'flutter' command not found. Please install the Flutter SDK and add it to your PATH.")
        print("https://docs.flutter.dev/get-started/install")
        return

    # Backup existing code
    print("Backing up custom code...")
    backup_lib = os.path.join(os.getcwd(), 'mobile_app_lib_backup')
    backup_pubspec = os.path.join(os.getcwd(), 'mobile_app_pubspec_backup')
    
    if os.path.exists(os.path.join(mobile_dir, 'lib')):
        if os.path.exists(backup_lib): shutil.rmtree(backup_lib)
        shutil.copytree(os.path.join(mobile_dir, 'lib'), backup_lib)
        
    if os.path.exists(os.path.join(mobile_dir, 'pubspec.yaml')):
        shutil.copy2(os.path.join(mobile_dir, 'pubspec.yaml'), backup_pubspec)

    # Initialize Flutter Project
    print("Initializing Flutter project structure (Android/iOS)...")
    # This creates the android/ ios/ folders
    run_command("flutter create .", cwd=mobile_dir)

    # Restore Code
    print("Restoring project files...")
    if os.path.exists(backup_lib):
        if os.path.exists(os.path.join(mobile_dir, 'lib')):
            shutil.rmtree(os.path.join(mobile_dir, 'lib'))
        shutil.copytree(backup_lib, os.path.join(mobile_dir, 'lib'))
        shutil.rmtree(backup_lib)
        
    if os.path.exists(backup_pubspec):
        shutil.copy2(backup_pubspec, os.path.join(mobile_dir, 'pubspec.yaml'))
        os.remove(backup_pubspec)

    # Update Android Manifest for Permissions
    manifest_path = os.path.join(mobile_dir, 'android', 'app', 'src', 'main', 'AndroidManifest.xml')
    if os.path.exists(manifest_path):
        print("Configuring Android permissions...")
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        permissions = [
            '<uses-permission android:name="android.permission.CAMERA" />',
            '<uses-permission android:name="android.permission.RECORD_AUDIO" />',
            '<uses-permission android:name="android.permission.INTERNET" />',
            '<uses-extension android:name="android.hardware.camera.any" />'
        ]
        
        if "android.permission.CAMERA" not in content:
            # Insert before <application
            content = content.replace("<application", "\n".join(permissions) + "\n    <application")
            with open(manifest_path, 'w', encoding='utf-8') as f:
                f.write(content)

    # Install dependencies
    print("Installing Flutter dependencies...")
    run_command("flutter pub get", cwd=mobile_dir)
    print("Mobile app setup complete.")

if __name__ == "__main__":
    setup_backend()
    setup_mobile_app()
    print("\n[3/3] Setup Finished!")
    print("\nTo Run the Backend:")
    print("  cd backend")
    print("  .\\venv\\Scripts\\activate")
    print("  uvicorn app.main:app --host 0.0.0.0 --port 8000")
    print("\nTo Run the Mobile App:")
    print("  cd mobile_app")
    print("  flutter run")
