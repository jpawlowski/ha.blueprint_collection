"""Tests for the inverted_binary_sensor template blueprint."""

from __future__ import annotations

from homeassistant.const import STATE_UNAVAILABLE
from homeassistant.core import HomeAssistant
from homeassistant.setup import async_setup_component

from .conftest import InstallBlueprint

BLUEPRINT = "template/ha_blueprint_author/inverted_binary_sensor.yaml"

SOURCE = "binary_sensor.door"
INVERTED = "binary_sensor.inverted_door"


async def _setup(hass: HomeAssistant, install_blueprint: InstallBlueprint) -> None:
    path = install_blueprint(BLUEPRINT)
    assert await async_setup_component(
        hass,
        "template",
        {
            "template": [
                {
                    "use_blueprint": {
                        "path": path,
                        "input": {"reference_entity": SOURCE},
                    },
                    "name": "Inverted door",
                    "unique_id": "inverted_door_test",
                }
            ]
        },
    )
    await hass.async_block_till_done()


async def test_state_is_inverted(hass: HomeAssistant, install_blueprint: InstallBlueprint) -> None:
    """The created sensor always shows the opposite of the source."""
    hass.states.async_set(SOURCE, "on")
    await _setup(hass, install_blueprint)

    state = hass.states.get(INVERTED)
    assert state is not None
    assert state.state == "off"

    hass.states.async_set(SOURCE, "off")
    await hass.async_block_till_done()
    state = hass.states.get(INVERTED)
    assert state is not None
    assert state.state == "on"


async def test_unavailable_source_makes_sensor_unavailable(
    hass: HomeAssistant, install_blueprint: InstallBlueprint
) -> None:
    """The created sensor is unavailable while the source has no usable state."""
    hass.states.async_set(SOURCE, STATE_UNAVAILABLE)
    await _setup(hass, install_blueprint)

    state = hass.states.get(INVERTED)
    assert state is not None
    assert state.state == STATE_UNAVAILABLE
