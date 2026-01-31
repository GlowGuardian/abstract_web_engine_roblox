# Abstract Web Engine Template for Roblox

This repo provides a **template** for building a Roblox web engine that can fetch pages via `HttpService`, parse HTML/CSS/JS, and render content into Roblox UI. It is intentionally incomplete so you can expand it into a fully functional browser-like experience. Use it as a starting point to add full parsing, layout, and scripting.

## What's Included

- `HttpClient` for HTTP requests through `HttpService`
- `HtmlParser` that builds a DOM-like tree of elements, text nodes, comments, and doctypes
- `CssParser` that parses `<style>` blocks into selector/declaration rules
- `StyleResolver` that applies CSS rules + inline styles to DOM nodes
- `LayoutEngine` that performs a simple flow layout using computed styles
- `JsStub` placeholder for loading/executing JavaScript
- `Renderer` placeholder that renders a basic preview UI, with image placeholders
- `LinkRouter` to route clicks back to the engine
- Example client script for wiring the engine to a `ScreenGui`

## DOM + CSS Notes

The DOM builder uses an HTML5-inspired tokenizer + tree builder (start/end tags, comments, doctypes, raw text elements, and basic attribute parsing). The CSS parser handles simple selector rules and inline styles, with a minimal cascade based on selector specificity and inline overrides.

The layout engine uses a naive flow model to size elements based on text length and font size. It is a starting point for building a real layout system.

This is still a template and **not** a fully compliant HTML5 or CSS parser. It is intended to give you a structured baseline to expand into a browser-like system.

## Placeholder Behavior

Images are represented with the Roblox default placeholder asset:

```
rbxasset://textures/ui/GuiImagePlaceholder.png
```

This is where you can replace image loading with a real asset pipeline.

## Next Steps

- Add full HTML5 parsing and error recovery rules.
- Expand CSS selector support (descendants, combinators, media queries).
- Replace the layout engine with true box model, flex, and grid layout.
- Replace `JsStub` with a JavaScript interpreter (or remote execution).
- Add security/allowlist rules for `HttpService` usage.

## Example Setup

Place the `src` modules under `ReplicatedStorage` and run the example in `examples/Starter.client.lua`.
