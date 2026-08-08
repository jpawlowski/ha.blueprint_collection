"""Tests for the flash_light script blueprint."""

from __future__ import annotations

import asyncio
from datetime import timedelta

from freezegun.api import FrozenDateTimeFactory
from pytest_homeassistant_custom_component.common import async_fire_time_changed, async_mock_service

from homeassistant.core import HomeAssistant
from homeassistant.setup import async_setup_component

from .conftest import InstallBlueprint

BLUEPRINT = "script/ha_blueprint_author/flash_light.yaml"

LIGHT = "light.lamp"


async def _settle() -> None:
    """Yield to the event loop until pending callbacks have run.

    Used instead of ``async_block_till_done`` while the script run is
    suspended in a delay - block_till_done would wait for the run to finish.
    """
    for _ in range(10):
        await asyncio.sleep(0)


async def test_flashes_requested_number_of_times(hass: HomeAssistant, install_blueprint: InstallBlueprint) -> None:
    """The script turns the light on and off flash_count times."""
    path = install_blueprint(BLUEPRINT)
    turn_on = async_mock_service(hass, "light", "turn_on")
    turn_off = async_mock_service(hass, "light", "turn_off")

    assert await async_setup_component(
        hass,
        "script",
        {
            "script": {
                "flash_test": {
                    "use_blueprint": {
                        "path": path,
                        "input": {
                            "light_target": {"entity_id": LIGHT},
                            "flash_count": 2,
                            "interval": 0,
                        },
                    }
                }
            }
        },
    )
    await hass.async_block_till_done()

    await hass.services.async_call("script", "flash_test", blocking=True)

    assert len(turn_on) == 2
    assert len(turn_off) == 2
    assert turn_on[0].data["entity_id"] == [LIGHT]


async def test_interval_paces_the_flashes(
    hass: HomeAssistant,
    install_blueprint: InstallBlueprint,
    freezer: FrozenDateTimeFactory,
) -> None:
    """The delay between transitions follows the configured interval.

    This demonstrates the canonical pattern for testing delays in blueprints:
    start the run without blocking, then advance time with the freezer and
    fire a time-changed event so pending delays complete.
    """
    path = install_blueprint(BLUEPRINT)
    turn_on = async_mock_service(hass, "light", "turn_on")
    turn_off = async_mock_service(hass, "light", "turn_off")

    assert await async_setup_component(
        hass,
        "script",
        {
            "script": {
                "flash_paced": {
                    "use_blueprint": {
                        "path": path,
                        "input": {
                            "light_target": {"entity_id": LIGHT},
                            "flash_count": 1,
                            "interval": 5,
                        },
                    }
                }
            }
        },
    )
    await hass.async_block_till_done()

    task = asyncio.ensure_future(hass.services.async_call("script", "flash_paced", blocking=True))
    # Let the script start: it turns the light on, then waits on the delay
    await _settle()
    assert len(turn_on) == 1
    assert len(turn_off) == 0

    # Advance past the first delay: the light turns off, second delay starts
    freezer.tick(timedelta(seconds=5))
    async_fire_time_changed(hass)
    await _settle()
    assert len(turn_off) == 1

    # Advance past the second delay: the run completes
    freezer.tick(timedelta(seconds=5))
    async_fire_time_changed(hass)
    await task

    assert len(turn_on) == 1
    assert len(turn_off) == 1
