import os
from docx import Document
from pptx import Presentation
from openpyxl import Workbook
from PIL import Image
from reportlab.pdfgen import canvas
os.makedirs("samples", exist_ok=True)
c = canvas.Canvas("samples/sample.pdf"); c.drawString(72, 720, "Hello sample PDF text"); c.showPage(); c.drawString(72, 720, "Page two"); c.save()
d = Document(); d.add_paragraph("Hello sample Word document"); d.save("samples/sample.docx")
p = Presentation(); s = p.slides.add_slide(p.slide_layouts[1]); s.shapes.title.text = "Hello slide"; p.save("samples/sample.pptx")
w = Workbook(); w.active["A1"] = "Hello"; w.save("samples/sample.xlsx")
open("samples/sample.txt", "w").write("Hello sample text file\nSecond line\n")
Image.new("RGB", (400, 300), (200, 80, 80)).save("samples/sample.jpg")
