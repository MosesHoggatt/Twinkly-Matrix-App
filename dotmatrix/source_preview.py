"""Source preview window utilities."""

import pygame

try:
    from pygame._sdl2.video import Window as SDLWindow, Renderer as SDLRenderer, Texture as SDLTexture
except ImportError:
    SDLWindow = SDLRenderer = SDLTexture = None


class SourcePreview:
    def __init__(self, width, height, enabled=False):
        self.enabled = bool(enabled and SDLWindow and SDLRenderer)
        self.window = None
        self.renderer = None
        self.texture = None
        if self.enabled:
            self.window = SDLWindow("Source Canvas", size=(width, height), position=(50, 50))
            self.renderer = SDLRenderer(self.window)

    def update(self, surface):
        if not (self.enabled and self.renderer and SDLTexture):
            return
        try:
            rendered_texture = SDLTexture.from_surface(self.renderer, surface)
            self.renderer.clear()
            if hasattr(self.renderer, "copy"):
                self.renderer.copy(rendered_texture, None, None)
            elif hasattr(rendered_texture, "draw"):
                rendered_texture.draw(None)
            else:
                return
            self.renderer.present()
            self.texture = rendered_texture
        except Exception:
            self.enabled = False
            self.window = None
            self.renderer = None
