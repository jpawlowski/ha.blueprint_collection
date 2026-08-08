"""Shared fixtures for blueprint tests.

The ``hass`` fixture comes from pytest-homeassistant-custom-component and
provides a fully functional in-memory Home Assistant instance per test.
"""

from __future__ import annotations

from collections.abc import Callable
from pathlib import Path
import shutil

import pytest

from homeassistant.core import HomeAssistant

REPO_ROOT = Path(__file__).parent.parent
BLUEPRINTS_ROOT = REPO_ROOT / "blueprints"

type InstallBlueprint = Callable[[str], str]


@pytest.fixture
def install_blueprint(hass: HomeAssistant) -> InstallBlueprint:
    """Install a repository blueprint into the test instance's config dir.

    Takes a path relative to blueprints/ (e.g.
    "automation/ha_blueprint_author/motion_light.yaml") and returns the
    ``use_blueprint.path`` value, i.e. the path relative to the domain folder
    ("ha_blueprint_author/motion_light.yaml").
    """

    def _install(rel_path: str) -> str:
        src = BLUEPRINTS_ROOT / rel_path
        if not src.is_file():
            msg = f"Blueprint not found in repository: blueprints/{rel_path}"
            raise FileNotFoundError(msg)
        dest = Path(hass.config.path("blueprints")) / rel_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(src, dest)
        return rel_path.split("/", 1)[1]

    return _install
