# Phoenix Window Manager Module

This module sets up [Phoenix](https://github.com/kasper/phoenix), a lightweight macOS window manager scriptable with JavaScript, along with [Karabiner-Elements](https://karabiner-elements.pqrs.org/) keyboard customizations.

Based on [fabiospampinato/phoenix](https://github.com/fabiospampinato/phoenix).

## What This Module Does

1. **Installs Phoenix configuration** - Symlinks the Phoenix JS config to `~/.config/phoenix/`
2. **Configures Karabiner-Elements** - Sets up keyboard remappings for ergonomic shortcuts
3. **Installs Alfred** - For the space switcher feature (added to homebrew.nix)

## Keyboard Mappings

| Key | Behavior |
|-----|----------|
| **Tab** (held + other key) | Acts as Hyper (Ctrl+Alt+Cmd) for Phoenix shortcuts |
| **Tab** (tapped alone) | Sends regular Tab |
| **Caps Lock** | Sends F18 (triggers space switcher) |

## Phoenix Shortcuts

| Shortcut | Action |
|----------|--------|
| `Tab + Arrow` | Move window to side (top/right/bottom/left) |
| `Tab + Q/W/A/S` | Move window to corner |
| `Tab + 1/2/3` | Move window to third |
| `Tab + [/]` | Move window to half |
| `Tab + Space` | Expand window to fill space |
| `Tab + Shift + Space` | Toggle fullscreen |
| `Tab + X` | Center window |
| `Tab + Shift + Arrow` | Grow window from edge |
| `Caps Lock` | Open space switcher (requires Alfred) |

## File Structure

```
phoenix/
├── config/
│   ├── constants.js      # Configurable values (gaps, sizes, etc.)
│   ├── karabiner.json    # Karabiner rules for Tab->Hyper, CapsLock->F18
│   └── phoenix.js        # Phoenix app settings
├── helpers/              # Utility functions
├── shortcuts/            # Keyboard shortcut definitions
├── magic/                # App-specific window behaviors
├── mouse/                # Mouse snapping functionality
├── spaces/               # Space switcher (requires Alfred)
├── icons/                # Icons for the space switcher
├── scripts/
│   └── setup-karabiner.sh  # Activation script for Karabiner rules
└── phoenix.js            # Main entry point
```

## Post-Installation Setup

After running `darwin-rebuild switch`, you need to:

1. **Grant Phoenix accessibility permissions**
   - System Settings → Privacy & Security → Accessibility → Enable Phoenix

2. **Grant Karabiner permissions** (it will prompt on first launch)

3. **Configure Mission Control shortcuts** (for space switching with numbers):
   - System Settings → Keyboard → Keyboard Shortcuts → Mission Control
   - Bind "Switch to Desktop 1-9" to `Ctrl+Alt+Cmd+Shift+1-9`

4. **Install alfred-spaces-workflow** (optional, for space switcher):
   - Download from https://github.com/fabiospampinato/alfred-spaces-workflow
   - Double-click the `.alfredworkflow` file to install

## Customization

- **Adjust gaps/sizes**: Edit `config/constants.js`
- **Change shortcuts**: Edit files in `shortcuts/`
- **Disable features**: Comment out `require()` calls in `phoenix.js`
- **Add Karabiner rules**: Edit `config/karabiner.json` and update `scripts/setup-karabiner.sh`

## Dependencies

- Phoenix (installed via Homebrew cask)
- Karabiner-Elements (installed via Homebrew cask)
- Alfred (installed via Homebrew cask, optional for space switcher)
- jq (used by activation script)
