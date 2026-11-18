"""Builds a realistic phone's worth of mock files under samples/<device path>/.

Covers every type the app lists or converts (pdf, docx, doc, pptx, xlsx, xls,
csv, txt, jpg, png), plus the cases that break readers on real phones: big and
many-page PDFs, scanned image PDFs, encrypted PDFs, corrupt and empty files,
unicode / spaced / upper-case names, deep and hidden folders, and a few hundred
files for scan speed.
"""
import io, os, random, shutil
from docx import Document
from docx.shared import Inches
from pptx import Presentation
from pptx.util import Inches as PInches
from openpyxl import Workbook
from PIL import Image, ImageDraw
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from pypdf import PdfReader, PdfWriter

random.seed(7)
ROOT = "samples"
shutil.rmtree(ROOT, ignore_errors=True)
LOREM = ("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod "
         "tempor incididunt ut labore et dolore magna aliqua. ")


def path(rel):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def image(rel, w=800, h=600, fmt=None, label="photo"):
    img = Image.new("RGB", (w, h), tuple(random.randint(40, 220) for _ in range(3)))
    d = ImageDraw.Draw(img)
    for _ in range(12):
        x, y = random.randint(0, w), random.randint(0, h)
        d.ellipse([x, y, x + w // 6, y + h // 6], fill=tuple(random.randint(0, 255) for _ in range(3)))
    d.text((20, 20), label, fill=(255, 255, 255))
    img.save(path(rel), fmt)
    return img


def pdf(rel, pages=2, title="Document", with_image=False):
    p = path(rel)
    c = canvas.Canvas(p, pagesize=A4)
    for i in range(pages):
        c.setFont("Helvetica-Bold", 18); c.drawString(72, 780, f"{title} - page {i + 1}")
        c.setFont("Helvetica", 11)
        y = 750
        for _ in range(30):
            c.drawString(72, y, LOREM[:95]); y -= 20
        if with_image:
            buf = io.BytesIO(); image("tmp/x.jpg", 1200, 900); c.drawImage(path("tmp/x.jpg"), 72, 80, 450, 300)
        c.showPage()
    c.save()


def docx(rel, paras=6, table=False, picture=False, title="Report"):
    d = Document(); d.add_heading(title, 0)
    for i in range(paras):
        d.add_heading(f"Section {i + 1}", 1) if i % 3 == 0 else None
        d.add_paragraph(LOREM * 3)
    if table:
        t = d.add_table(rows=6, cols=4); t.style = "Table Grid"
        for r in range(6):
            for c in range(4):
                t.cell(r, c).text = f"R{r}C{c}"
    if picture:
        image("tmp/pic.png", 600, 400, label="chart"); d.add_picture(path("tmp/pic.png"), width=Inches(4))
    d.save(path(rel))


def pptx(rel, slides=3, picture=False):
    p = Presentation()
    for i in range(slides):
        s = p.slides.add_slide(p.slide_layouts[1])
        s.shapes.title.text = f"Slide {i + 1}"
        s.placeholders[1].text = "Point one\nPoint two\nPoint three"
        if picture and i == 0:
            image("tmp/s.jpg", 800, 600); s.shapes.add_picture(path("tmp/s.jpg"), PInches(5), PInches(2), PInches(4))
    p.save(path(rel))


def xlsx(rel, sheets=1, rows=20):
    w = Workbook()
    for si in range(sheets):
        ws = w.active if si == 0 else w.create_sheet()
        ws.title = f"Sheet{si + 1}"
        ws.append(["Item", "Qty", "Price", "Total"])
        for r in range(rows):
            q, pr = random.randint(1, 9), round(random.uniform(1, 99), 2)
            ws.append([f"Item {r + 1}", q, pr, f"=B{r + 2}*C{r + 2}"])
    w.save(path(rel))


# --- Files the device test opens and converts by name (newest, easy to find) ---
pdf("Download/test_open.pdf", 3, "Open test")
docx("Download/test_open.docx", table=True, picture=True, title="Open test")
pptx("Download/test_open.pptx", 3, picture=True)
xlsx("Download/test_open.xlsx", 2)
docx("Download/convert_me.docx", 12, table=True, picture=True, title="Convert me")
xlsx("Download/convert_me.xlsx", 2, 40)
pptx("Download/convert_me.pptx", 5, picture=True)
pdf("Download/convert_me.pdf", 4, "Convert me")
open(path("Download/convert_me.txt"), "w").write(("A plain text note.\n" + LOREM + "\n") * 20)
image("Download/convert_me.jpg", 1600, 1200, label="convert me")
image("Download/convert_me_2.png", 1080, 1920, "PNG", label="screenshot")

# --- Everyday documents in the usual places ---
for i in range(1, 9):
    pdf(f"Download/invoice_2026_{i:02d}.pdf", random.randint(1, 3), f"Invoice {i}")
pdf("Documents/Big manual (120 pages).pdf", 120, "Manual")
pdf("Documents/Scanned/scan_photo_pdf.pdf", 6, "Scan", with_image=True)
pdf("Documents/Résumé – Muhammad.pdf", 2, "Résumé")
pdf("Documents/UPPERCASE.PDF", 1, "Upper")
docx("Documents/Work/Quarterly report Q3.docx", 30, table=True, picture=True)
docx("Documents/Work/meeting notes.docx", 4)
docx("Documents/Work/تقرير عربي.docx", 3, title="Arabic name")
pptx("Documents/Work/Pitch deck.pptx", 12, picture=True)
xlsx("Documents/Work/Budget 2026.xlsx", 3, 200)
open(path("Documents/Work/export.csv"), "w").write("a,b,c\n" + "\n".join(f"{i},{i*2},{i*3}" for i in range(500)))
open(path("Documents/notes.txt"), "w").write("Shopping list\nMilk\nEggs\n")
pdf("WhatsApp/Media/WhatsApp Documents/Lecture 5.pdf", 25, "Lecture")
docx("WhatsApp/Media/WhatsApp Documents/Assignment.docx", 8, table=True)
pptx("WhatsApp/Media/WhatsApp Documents/Slides week 3.pptx", 15)
pdf("Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents/Form.pdf", 2, "Form")
pdf("Telegram/Telegram Documents/book.pdf", 40, "Book")
pdf("Download/a/b/c/d/deep/nested file.pdf", 1, "Deep")
pdf("Documents/.hidden/secret.pdf", 1, "Hidden")
for i in range(1, 7):
    image(f"DCIM/Camera/IMG_2026111{i}_1200{i}.jpg", 4000, 3000, label=f"camera {i}")
for i in range(1, 4):
    image(f"Pictures/Screenshots/Screenshot_2026-11-1{i}.png", 1080, 2400, "PNG", label="screen")

# --- Edge cases ---
w = PdfWriter(); w.append(PdfReader(path("Download/invoice_2026_01.pdf"))); w.encrypt("1234")
with open(path("Documents/Locked (password 1234).pdf"), "wb") as f: w.write(f)
open(path("Documents/Broken/corrupt.pdf"), "wb").write(b"%PDF-1.4\n" + os.urandom(3000))
open(path("Documents/Broken/corrupt.docx"), "wb").write(os.urandom(4000))
open(path("Documents/Broken/corrupt.pptx"), "wb").write(b"PK\x03\x04" + os.urandom(2000))
open(path("Documents/Broken/corrupt.xlsx"), "wb").write(os.urandom(1500))
open(path("Documents/Broken/empty.pdf"), "wb").close()
open(path("Documents/Broken/empty.docx"), "wb").close()
open(path("Documents/Broken/old_format.doc"), "wb").write(bytes.fromhex("D0CF11E0A1B11AE1") + os.urandom(4000))
open(path("Documents/Broken/old_format.xls"), "wb").write(bytes.fromhex("D0CF11E0A1B11AE1") + os.urandom(4000))
open(path("Documents/Broken/old_format.ppt"), "wb").write(bytes.fromhex("D0CF11E0A1B11AE1") + os.urandom(4000))
open(path("Documents/Broken/not really a pdf.pdf"), "w").write("<html>this is html</html>")

# --- Volume: a few hundred small files for scan speed ---
for i in range(250):
    kind = i % 4
    rel = f"Download/archive/{i // 50}/file_{i:03d}"
    if kind == 0: pdf(rel + ".pdf", 1, f"Archive {i}")
    elif kind == 1: docx(rel + ".docx", 1)
    elif kind == 2: open(path(rel + ".txt"), "w").write(f"note {i}\n")
    else: xlsx(rel + ".xlsx", 1, 3)

shutil.rmtree(path("tmp"), ignore_errors=True)
total = sum(len(f) for _, _, f in os.walk(ROOT))
size = sum(os.path.getsize(os.path.join(d, x)) for d, _, f in os.walk(ROOT) for x in f)
print(f"mock files: {total}, {size / 1e6:.1f} MB")
