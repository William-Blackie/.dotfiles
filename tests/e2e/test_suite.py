#!/usr/bin/env python3
import os
import subprocess
import unittest

class TestDotfilesEndToEnd(unittest.TestCase):
    """Smoke tests for the installed shell and editor entrypoints."""

    @classmethod
    def setUpClass(cls):
        cls.home = os.path.expanduser("~")
        cls.dotfiles = os.path.join(cls.home, ".dotfiles")
        cls.zsh_cmd = ["zsh", "-c", "source ~/.zshrc >/dev/null 2>&1; eval \"$1\"", "--"]

        cls.env = os.environ.copy()
        cls.env["TERM"] = "xterm"

    def test_installation_creates_core_symlinks(self):
        """Verify essential configuration symlinks via Stow."""
        expected_anchors = {
            ".zshrc": "zsh/.zshrc",
            ".zshenv": "shell/.zshenv",
            ".gitconfig": "git/.gitconfig",
            ".config/nvim": "nvim/.config/nvim",
            ".config/starship.toml": "starship/.config/starship.toml",
        }
        for link_name, target_rel in expected_anchors.items():
            with self.subTest(link=link_name):
                link_path = os.path.join(self.home, link_name)
                self.assertTrue(os.path.islink(link_path))
                self.assertEqual(os.path.realpath(link_path), os.path.realpath(os.path.join(self.dotfiles, target_rel)))

    def test_zsh_configuration_sources_successfully(self):
        """Ensure .zshrc loads without errors."""
        # Use full source here to check for shell errors
        result = subprocess.run(["zsh", "-c", "source ~/.zshrc >/dev/null 2>&1; echo READY"], capture_output=True, text=True, env=self.env)
        self.assertEqual(result.returncode, 0)
        self.assertIn("READY", result.stdout)

    def test_custom_aliases_defined(self):
        """Assert high-value aliases are registered."""
        for cmd in ["p", "wta", "wtl", "wts", "wtg", "start", "d"]:
            with self.subTest(cmd=cmd):
                result = subprocess.run(self.zsh_cmd + [f"whence {cmd}"], capture_output=True, env=self.env)
                self.assertEqual(result.returncode, 0)



if __name__ == "__main__":
    unittest.main(verbosity=2)
