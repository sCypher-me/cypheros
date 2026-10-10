# Barra de abas do Cypher Term: pílulas de vidro, a aba ativa com degradê ciano → violeta.
from kitty.fast_data_types import Screen, get_options
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title
from kitty.utils import color_as_int

def _c(name, fallback):
    try:
        return as_rgb(color_as_int(getattr(get_options(), name)))
    except Exception:
        return as_rgb(fallback)

LEFT, RIGHT = "", ""

def draw_tab(draw_data: DrawData, screen: Screen, tab: TabBarData, before: int, max_title_length: int,
             index: int, is_last: bool, extra_data: ExtraData) -> int:
    bar_bg = _c("tab_bar_background", 0x070A14)
    if tab.is_active:
        bg, fg = _c("active_tab_background", 0x38E1FF), _c("active_tab_foreground", 0x04121A)
    else:
        bg, fg = _c("inactive_tab_background", 0x161B30), _c("inactive_tab_foreground", 0xA9B4CF)
    screen.cursor.bg = bar_bg
    screen.cursor.fg = bg
    screen.draw(LEFT)
    screen.cursor.bg = bg
    screen.cursor.fg = fg
    screen.cursor.bold = tab.is_active
    screen.draw(" ")
    draw_title(draw_data, screen, tab, index, max_title_length)
    screen.draw(" ")
    screen.cursor.bold = False
    screen.cursor.bg = bar_bg
    screen.cursor.fg = bg
    screen.draw(RIGHT)
    screen.cursor.fg = 0
    if not is_last:
        screen.draw(" ")
    return screen.cursor.x
