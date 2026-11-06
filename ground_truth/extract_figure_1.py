# coppock_2025/ground_truth/extract_figure_1.py
# Output: ground_truth/figure_1_plotted.csv
# Depends on: the article PDF, passed as the first argument (not redistributed; see README)
# Description: Read the plotted positions of Figure 1's panels a, b, c, and e out of the PDF's
#   vector marks, converting each to data units through that panel's own axis ticks. These
#   are the published values, so the extraction takes nothing from the data. Panel d's
#   points and ribbons are not read; the README says why.
import csv
import sys

import pymupdf

BLUE, RED, GREY = (0.12, 0.23, 0.58), (0.85, 0.12, 0.09), (0.2, 0.2, 0.2)
COLOUR_LABEL = {BLUE: "printed_democrat", RED: "printed_republican"}

# Panel, facet, plot rows in the published order, and the printed tick labels left to right.
PANELS = [
    ("a", "Democratic", ["two_thirds", "citizenship", "arming_teachers", "minimum_wage"], 149, 0, [-0.2, -0.1, 0.0, 0.1]),
    ("a", "Republican", ["two_thirds", "citizenship", "arming_teachers", "minimum_wage"], 149, 4, [-0.2, -0.1, 0.0, 0.1]),
    ("b", "Republicans control 60%", ["chamber"], 242, 0, [-0.2, 0.0, 0.2, 0.4]),
    ("c", "Obama", ["chili", "meatloaf", "lasagna", "salmon"], 371, 0, [-0.2, -0.1, 0.0, 0.1]),
    ("c", "Trump", ["chili", "meatloaf", "lasagna", "salmon"], 371, 4, [-0.2, -0.1, 0.0, 0.1]),
    ("e", "Democratic", ["risky_tax"], 625, 0, [-0.1, 0.0, 0.1, 0.2, 0.3]),
    ("e", "Republican", ["risky_tax"], 625, 5, [-0.1, 0.0, 0.1, 0.2, 0.3]),
]


def colour(d, key):
    c = d.get(key)
    return tuple(round(x, 2) for x in c) if c else None


drawings = pymupdf.open(sys.argv[1])[1].get_drawings()
ticks = [d["rect"] for d in drawings if d["type"] == "s" and colour(d, "color") == GREY
         and d["rect"].width < 0.01 and d["rect"].height < 4]
marks = [d for d in drawings if d["type"] == "f" and colour(d, "fill") in COLOUR_LABEL
         and len(d["items"]) in (3, 4) and d["rect"].width < 5]
lines = [d for d in drawings if d["type"] == "s" and colour(d, "color") in COLOUR_LABEL]

rows = []
for panel, facet, items, tick_y, first, labels in PANELS:
    xs = sorted(t.x0 for t in ticks if abs(t.y0 - tick_y) < 1.5)[first:first + len(labels)]
    slope = (labels[-1] - labels[0]) / (xs[-1] - xs[0])
    to_data = lambda x: labels[0] + (x - xs[0]) * slope
    top = tick_y - 8 - 95 if panel in ("a", "c") else tick_y - 40
    for col_name, col in COLOUR_LABEL.items():
        in_panel = [m for m in marks if colour(m, "fill") == col_name and top < m["rect"].y0 < tick_y
                    and xs[0] - 40 < m["rect"].x0 < xs[-1] + 40]
        in_panel.sort(key=lambda m: m["rect"].y0)
        assert len(in_panel) == len(items), (panel, facet, col, len(in_panel))
        for item, m in zip(items, in_panel):
            y = (m["rect"].y0 + m["rect"].y1) / 2
            seg = [s["rect"] for s in lines if colour(s, "color") == col_name
                   and abs(s["rect"].y0 - y) < 1.2 and s["rect"].x0 <= m["rect"].x1 and s["rect"].x1 >= m["rect"].x0]
            assert len(seg) == 1, (panel, facet, item, col, len(seg))
            rows.append({"panel": panel, "facet": facet, "item": item, "printed_group": col,
                         "estimate": round(to_data((m["rect"].x0 + m["rect"].x1) / 2), 4),
                         "conf_low": round(to_data(seg[0].x0), 4),
                         "conf_high": round(to_data(seg[0].x1), 4)})

with open("ground_truth/figure_1_plotted.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(rows)
print(f"{len(rows)} plotted estimates written")
