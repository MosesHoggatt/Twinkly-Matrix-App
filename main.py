import os
from dotmatrix import DotMatrix

HEADLESS = 'DISPLAY' not in os.environ

if HEADLESS:
    os.environ['SDL_VIDEODRIVER'] = 'dummy'
    os.environ['SDL_AUDIODRIVER'] = 'dummy'
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'


def main():
    matrix = DotMatrix(
        show_source_preview=(not HEADLESS),
        headless=HEADLESS,
        fpp_output=True
    )
    matrix.animated_bouncing_ball()
    matrix.wait_for_exit()


if __name__ == "__main__":
    main()