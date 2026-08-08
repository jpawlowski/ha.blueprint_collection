"""Tests for the motion_light automation blueprint."""

from __future__ import annotations

import asyncio

from pytest_homeassistant_custom_component.common import async_mock_service

from homeassistant.core import HomeAssistant
from homeassistant.setup import async_setup_component

from .conftest import InstallBlueprint

BLUEPRINT = "automation/ha_blueprint_author/motion_light.yaml"

MOTION = "binary_sensor.motion"
LIGHT = "light.lamp"


async def _settle(hass: HomeAssistant) -> None:
    """Let the automation run up to its suspension point.

    The blueprint suspends in wait_for_trigger until motion clears, so a full
    ``async_block_till_done()`` would wait forever on the still-running
    automation task. Yielding to the event loop a few times is enough to let
    the actions before the suspension point execute.
    """
    for _ in range(5):
        await asyncio.sleep(0)


async def _setup(hass: HomeAssistant, install_blueprint: InstallBlueprint, wait: int) -> None:
    path = install_blueprint(BLUEPRINT)
    hass.states.async_set(MOTION, "off")
    assert await async_setup_component(
        hass,
        "automation",
        {
            "automation": {
                "alias": "Motion light test",
                "use_blueprint": {
                    "path": path,
                    "input": {
                        "motion_entity": MOTION,
                        "light_target": {"entity_id": LIGHT},
                        "no_motion_wait": wait,
                    },
                },
            }
        },
    )
    await hass.async_block_till_done()


async def test_light_turns_on_with_motion(hass: HomeAssistant, install_blueprint: InstallBlueprint) -> None:
    """Light turns on as soon as motion is detected."""
    await _setup(hass, install_blueprint, wait=0)
    turn_on = async_mock_service(hass, "light", "turn_on")

    hass.states.async_set(MOTION, "on")
    await _settle(hass)

    assert len(turn_on) == 1
    assert turn_on[0].data["entity_id"] == [LIGHT]


async def test_light_turns_off_after_motion_clears(hass: HomeAssistant, install_blueprint: InstallBlueprint) -> None:
    """Light turns off after motion clears and the wait time has passed."""
    await _setup(hass, install_blueprint, wait=0)
    turn_on = async_mock_service(hass, "light", "turn_on")
    turn_off = async_mock_service(hass, "light", "turn_off")

    hass.states.async_set(MOTION, "on")
    await _settle(hass)
    assert len(turn_on) == 1
    assert len(turn_off) == 0

    # Motion clears: wait_for_trigger resolves, the wait time (0s) passes,
    # and the run completes - so a full block_till_done is safe here.
    hass.states.async_set(MOTION, "off")
    await hass.async_block_till_done()

    assert len(turn_off) == 1
    assert turn_off[0].data["entity_id"] == [LIGHT]


async def test_light_stays_on_while_motion_continues(hass: HomeAssistant, install_blueprint: InstallBlueprint) -> None:
    """Light is not turned off while motion is still detected."""
    await _setup(hass, install_blueprint, wait=0)
    async_mock_service(hass, "light", "turn_on")
    turn_off = async_mock_service(hass, "light", "turn_off")

    hass.states.async_set(MOTION, "on")
    await _settle(hass)

    assert len(turn_off) == 0
