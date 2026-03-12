#!/usr/bin/env python3
import os
import subprocess
import sys

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    tests_dir = os.path.join(root_dir, "tests", "e2e")
    
    print("🚀 Building E2E Docker Image...")
    # Give the image a unique name
    image_name = "dotfiles-e2e:latest"
    # Build from root_dir context so COPY . works correctly
    build_cmd = ["docker", "build", "-t", image_name, "-f", os.path.join(tests_dir, "Dockerfile"), root_dir]
    
    # Check if docker is running/available before trying to build
    try:
        subprocess.run(["docker", "info"], check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("⚠️  Docker is not available. Skipping true E2E tests.")
        sys.exit(0)
    
    if subprocess.run(build_cmd).returncode != 0:
        print("❌ Failed to build Docker image.")
        sys.exit(1)
        
    print("🧪 Running E2E Test Suite in Docker...")
    # Mount the dotfiles folder into the container
    # -t is required for zsh -i to load correctly
    run_cmd = [
        "docker", "run", "--rm",
        "-v", f"{root_dir}:/home/testuser/.dotfiles",
        "-t",
        image_name
    ]
    
    try:
        # 10 minute timeout for the whole suite
        result = subprocess.run(run_cmd, timeout=600)
        if result.returncode == 0:
            print("✅ E2E Tests Passed!")
        else:
            print("❌ E2E Tests Failed!")
            sys.exit(result.returncode)
    except subprocess.TimeoutExpired:
        print("❌ E2E Tests Timed Out!")
        # Try to kill the container if it's still running?
        # subprocess.run(["docker", "ps", "-q", "--filter", f"ancestor={image_name}", "|", "xargs", "docker", "kill"])
        sys.exit(1)

if __name__ == "__main__":
    main()
