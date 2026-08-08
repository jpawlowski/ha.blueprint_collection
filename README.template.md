# Blueprint Collection

[![GitHub Release][releases-shield]][releases]
[![GitHub Activity][commits-shield]][commits]
[![License][license-shield]](LICENSE)

![Project Maintenance][maintenance-shield]

<!--
Uncomment and customize these badges if you want to use them:

[![BuyMeCoffee][buymecoffeebadge]][buymecoffee]
[![Discord][discord-shield]][discord]
-->

A collection of [Home Assistant blueprints][blueprint-docs] — reusable automations, scripts, and template entities
that you can import into your own Home Assistant instance with one click.

Every blueprint in this collection is validated against Home Assistant's own blueprint schema and covered by
automated runtime tests, so it actually does what it says.

## 📦 Blueprints

Click a badge to open the import dialog in your own Home Assistant instance.

<!-- Regenerate this section with: ./script/import-links -->

### Automation blueprints

#### Motion-activated light

Turn a light on when motion is detected and turn it off again after no motion has been detected for a configurable wait time.

[![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjpawlowski%2Fha.blueprint_collection%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fha_blueprint_author%2Fmotion_light.yaml)

### Script blueprints

#### Flash light

Flash a light a configurable number of times. Useful as a visual notification, for example when a door opens or a timer finishes.

[![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjpawlowski%2Fha.blueprint_collection%2Fblob%2Fmain%2Fblueprints%2Fscript%2Fha_blueprint_author%2Fflash_light.yaml)

### Template blueprints

#### Inverted binary sensor

Create a binary sensor that always shows the opposite of a reference binary sensor. The sensor is unavailable while the reference entity has no usable state.

[![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjpawlowski%2Fha.blueprint_collection%2Fblob%2Fmain%2Fblueprints%2Ftemplate%2Fha_blueprint_author%2Finverted_binary_sensor.yaml)

## 🚀 How to use a blueprint

1. **Import it** — click the badge above, or go to
   **Settings > Automations & scenes > Blueprints > Import blueprint** and paste the blueprint's URL
2. **Create from it** — click **Create automation** (or **Add script**) on the imported blueprint
3. **Fill in the inputs** — pick your entities and adjust the options; fields with defaults can be left alone
4. **Save** — that's it

**Requirements:** Home Assistant 2024.10.0 or newer (each blueprint states its own minimum version).

## 🔄 Updating

Home Assistant does not update imported blueprints automatically. To pick up fixes and improvements:

**Settings > Automations & scenes > Blueprints > (blueprint) > ⋮ > Re-import blueprint**

Automations and scripts you created from the blueprint keep working and use the updated version immediately.
Check the [release notes][releases] before re-importing — breaking changes are called out there.

## 🐛 Problems and ideas

- **Something broken?** [Open a bug report][issues] and include which blueprint, your Home Assistant version,
  and the automation trace (**Settings > Automations > (your automation) > Traces**)
- **Missing a feature?** [Open a feature request][issues]

## 🤝 Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). This repository ships a complete development
environment (DevContainer, a real Home Assistant instance, schema validation, and a runtime test suite), so you can
develop and verify blueprint changes properly instead of testing by hand.

**✨ Develop in the cloud:** no local setup required.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/jpawlowski/ha.blueprint_collection?quickstart=1)

## 📄 License

[MIT](LICENSE)

---

[blueprint-docs]: https://www.home-assistant.io/docs/blueprint/
[commits-shield]: https://img.shields.io/github/commit-activity/y/jpawlowski/ha.blueprint_collection.svg?style=for-the-badge
[commits]: https://github.com/jpawlowski/ha.blueprint_collection/commits/main
[issues]: https://github.com/jpawlowski/ha.blueprint_collection/issues
[license-shield]: https://img.shields.io/github/license/jpawlowski/ha.blueprint_collection.svg?style=for-the-badge
[maintenance-shield]: https://img.shields.io/badge/maintainer-%40jpawlowski-blue.svg?style=for-the-badge
[releases-shield]: https://img.shields.io/github/release/jpawlowski/ha.blueprint_collection.svg?style=for-the-badge
[releases]: https://github.com/jpawlowski/ha.blueprint_collection/releases

<!--
[buymecoffee]: https://www.buymeacoffee.com/jpawlowski
[buymecoffeebadge]: https://img.shields.io/badge/buy%20me%20a%20coffee-donate-yellow.svg?style=for-the-badge
[discord]: https://discord.gg/Qa5fW2R
[discord-shield]: https://img.shields.io/discord/330944238910963714.svg?style=for-the-badge
-->
