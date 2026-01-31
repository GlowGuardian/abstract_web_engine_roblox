# Abstract Web Engine Template for Roblox

This repo provides a **template** for building a Roblox web engine that can fetch pages via `HttpService`, parse HTML/CSS/JS, and render content into Roblox UI. It is intentionally incomplete so you can expand it into a fully functional browser-like experience. Use it as a starting point to add full parsing, layout, and scripting.

## What's Included

- `HttpClient` for HTTP requests through `HttpService`
- `HtmlParser` that builds a DOM-like tree of elements, text nodes, comments, and doctypes
- `CssParser` placeholder for extracting `<style>` blocks
- `JsStub` placeholder for loading/executing JavaScript
- `Renderer` placeholder that renders a basic preview UI, with image placeholders
- `LinkRouter` to route clicks back to the engine
- Example client script for wiring the engine to a `ScreenGui`

## DOM Tree Notes

The DOM builder now handles nested elements, basic attributes (quoted/unquoted/boolean), raw text elements (`<script>`, `<style>`), and comments. It is still a template and **not** a full HTML5-compliant parser yet.

## Placeholder Behavior

Images are represented with the Roblox default placeholder asset:

```
rbxasset://textures/ui/GuiImagePlaceholder.png
```

This is where you can replace image loading with a real asset pipeline.

## Next Steps

- Replace `CssParser` with a real CSS parser and style cascade.
- Add a layout engine (flow, flex, grid) to `Renderer`.
- Replace `JsStub` with a JavaScript interpreter (or remote execution).
- Add security/allowlist rules for `HttpService` usage.

## Example Setup

Place the `src` modules under `ReplicatedStorage` and run the example in `examples/Starter.client.lua`.
