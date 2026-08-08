# Contribution guidelines

Contributing to this project should be as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features

## GitHub is used for everything

GitHub is used to host code, to track issues and feature requests, as well as accept pull requests.

Pull requests are the best way to propose changes to the codebase.

AI-assisted contributions are welcome, including substantially AI-generated work. Read the
[`AI_POLICY.md`](AI_POLICY.md) before contributing. Be accurate about what you reviewed and tested, and do not present
automated checks as human review or real-device testing.

1. Fork the repo and create your branch from `main`.
2. Run `script/setup/bootstrap` to install dependencies and pre-commit hooks.
3. If you've changed something, update the documentation.
4. Make sure your code passes all checks (using `script/check` for linting and type checking).
5. Test your contribution.
6. Review the resulting diff and describe its verification accurately.
7. Issue that pull request!

## Any contributions you make will be under the MIT Software License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using GitHub's [issues](../../issues)

GitHub issues are used to track public bugs.
Report a bug by [opening a new issue](../../issues/new/choose); it's that easy!

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can.
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

People _love_ thorough bug reports. I'm not even kidding.

## Use a Consistent Coding Style

This project uses:

- [Ruff](https://github.com/astral-sh/ruff) for linting and formatting
- [Pyright](https://github.com/microsoft/pyright) for type checking

Run `script/check` to lint and type-check your code before submitting, or `script/lint` to auto-format and fix linting issues.

**Blueprint validation:** Run `script/blueprint-check` to validate your blueprints against Home Assistant's own blueprint schema (imported from the pinned Home Assistant version), plus this repository's rules — domain/folder match, input usage, `min_version`, and `source_url` correctness.

## GitHub Copilot Support

This project includes [prompt files](./.github/prompts/) to help you work more efficiently with GitHub Copilot. These reusable templates provide context and requirements for common tasks:

- **Add Blueprint** - Create a new blueprint with tests and an import link
- **Review Blueprint** - Check a blueprint for schema, UX, and breaking-change risks
- **Create ADR** - Record an architectural decision
- **Create Implementation Plan** - Plan a larger change

**Example usage in Copilot Chat:**

```text
#file:Add Blueprint.prompt.md Add an automation blueprint that turns off lights when everyone leaves
```

See the prompt files in `.github/prompts/` for details on using these templates.

## Code Quality

Blueprints in this collection are expected to meet a few standards:

- ✅ Complete metadata — name, description, author, `source_url`, `homeassistant.min_version`
- ✅ Every configurable value exposed as an input with a typed, filtered selector
- ✅ Sensible defaults so the blueprint works with minimal configuration
- ✅ `entity_id` references rather than `device_id`, and nothing hardcoded
- ✅ At least one runtime test covering the happy path

See [docs/development/AUTHORING.md](docs/development/AUTHORING.md) for the reasoning behind each of these.

## Test your code modification

This project comes with a complete development environment in a container, easy to launch
if you use Visual Studio Code. With this container you will have a standalone
Home Assistant instance running and already configured with the included
[`configuration.yaml`](./config/configuration.yaml) file.

Run `./script/develop` to start that instance with your blueprints linked in, then create an automation from a blueprint via **Settings > Automations & scenes > Blueprints** to try it interactively.

Run `script/test` to execute the runtime test suite — each test installs a blueprint into an in-memory Home Assistant instance and asserts its actual behavior. See [docs/development/TESTING.md](docs/development/TESTING.md).

## License

By contributing, you agree that your contributions will be licensed under its MIT License.
