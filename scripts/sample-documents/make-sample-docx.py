"""Builds the 3 sample documents (own content, fictional company) as DOCX; the engine turns them
into HWP. Usage: python make_docx.py <out_dir>"""
import sys
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Pt, RGBColor

OUT = sys.argv[1]
NAVY = RGBColor(0x1F, 0x3A, 0x68)
BLUE = RGBColor(0x2F, 0x6F, 0xED)
GRAY = RGBColor(0x6B, 0x72, 0x80)
RED = RGBColor(0xD9, 0x3B, 0x3B)


def para(doc, text="", size=11, bold=False, color=None, align=None, italic=False):
    p = doc.add_paragraph()
    if align == "center":
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    elif align == "right":
        p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    if text:
        r = p.add_run(text)
        r.font.size = Pt(size)
        r.bold = bold
        r.italic = italic
        if color is not None:
            r.font.color.rgb = color
    return p


def rich(doc, parts, size=11):
    """parts: [(text, bold, color)]"""
    p = doc.add_paragraph()
    for text, bold, color in parts:
        r = p.add_run(text)
        r.font.size = Pt(size)
        r.bold = bold
        if color is not None:
            r.font.color.rgb = color
    return p


def heading(doc, text, size=15, color=NAVY):
    return para(doc, text, size=size, bold=True, color=color)


def table(doc, rows, header_color=NAVY):
    t = doc.add_table(rows=len(rows), cols=len(rows[0]))
    t.style = "Table Grid"
    for i, row in enumerate(rows):
        for j, value in enumerate(row):
            cell = t.cell(i, j)
            cell.text = ""
            r = cell.paragraphs[0].add_run(value)
            r.font.size = Pt(10)
            if i == 0:
                r.bold = True
                r.font.color.rgb = header_color
                cell.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    return t


# ---------------------------------------------------------------- BusinessReport
doc = Document()
para(doc, "ABC 주식회사 · 경영기획팀", size=10, color=GRAY, align="right")
para(doc, "2026년 3분기 사업 보고서", size=24, bold=True, color=NAVY, align="center")
para(doc, "보고 기간: 2026. 7. 1. ~ 2026. 9. 30.", size=11, color=GRAY, align="center")
para(doc)
heading(doc, "1. 요약")
para(doc, "3분기 매출은 전년 동기 대비 18.4% 증가한 128억 원을 기록하였습니다. 신규 모바일 서비스의 "
          "유료 전환율이 개선되면서 영업이익률은 12.1%로 상승하였고, 해외 매출 비중도 처음으로 30%를 넘어섰습니다.")
rich(doc, [("핵심 성과: ", True, BLUE), ("매출 목표 103% 달성, 신규 고객 2만 4천 명 확보, 고객 만족도 4.6점", False, None)])
para(doc)
heading(doc, "2. 주요 지표")
table(doc, [
    ["구분", "목표", "실적", "달성률"],
    ["매출액", "124억 원", "128억 원", "103%"],
    ["영업이익", "14억 원", "15.5억 원", "111%"],
    ["신규 고객", "2만 명", "2.4만 명", "120%"],
    ["고객 만족도", "4.5점", "4.6점", "102%"],
])
para(doc)
heading(doc, "3. 사업부별 실적")
rich(doc, [("① 모바일 서비스  ", True, NAVY), ("문서 편집 기능 개편 이후 월간 이용자가 35% 늘었습니다.", False, None)])
rich(doc, [("② 기업 솔루션  ", True, NAVY), ("공공기관 3곳과 신규 계약을 체결하여 안정적인 매출 기반을 마련하였습니다.", False, None)])
rich(doc, [("③ 해외 사업  ", True, NAVY), ("일본·베트남 시장에서 현지화 버전을 출시하였습니다.", False, None)])
para(doc)
heading(doc, "4. 리스크 및 대응")
para(doc, "• 환율 변동에 따른 해외 매출 변동성 확대 → 분기별 환헤지 비율 점검")
para(doc, "• 경쟁 서비스의 무료 정책 강화 → 핵심 기능 중심의 요금제 개편 검토")
rich(doc, [("※ 4분기에는 마케팅 비용이 일시적으로 증가할 예정입니다.", False, RED)], size=10)
para(doc)
heading(doc, "5. 4분기 계획")
para(doc, "4분기에는 연간 목표 달성을 위해 신규 기능 출시와 고객 유지 프로그램에 집중하겠습니다. "
          "특히 협업 기능을 정식 출시하고, 기업 고객 대상 교육 프로그램을 확대할 계획입니다.")
para(doc)
para(doc, "※ 본 문서는 앱 기능을 소개하기 위한 예시 문서입니다.", size=9, color=GRAY, italic=True)
doc.save(f"{OUT}/BusinessReport.docx")

# ---------------------------------------------------------------- ProjectProposal
doc = Document()
para(doc, "프로젝트 제안서", size=12, bold=True, color=BLUE, align="center")
para(doc, "스마트 문서 관리 시스템 구축", size=24, bold=True, color=NAVY, align="center")
para(doc, "제안 부서: 디지털혁신팀  |  제안일: 2026. 10. 15.", size=11, color=GRAY, align="center")
para(doc)
heading(doc, "1. 제안 배경")
para(doc, "현재 사내 문서는 부서별로 서로 다른 저장소에 흩어져 있어 필요한 자료를 찾는 데 평균 20분 이상이 "
          "소요됩니다. 또한 외부에서는 HWP 문서를 열람하거나 수정하기 어려워 업무가 지연되는 사례가 늘고 있습니다.")
para(doc)
heading(doc, "2. 추진 목표")
para(doc, "1) 모든 업무 문서를 한곳에서 검색하고 열람할 수 있는 환경 구축")
para(doc, "2) 모바일에서도 HWP 문서를 바로 확인하고 수정할 수 있도록 지원")
para(doc, "3) 문서 보안 등급에 따른 접근 권한 관리 체계 마련")
para(doc)
heading(doc, "3. 추진 일정")
table(doc, [
    ["단계", "주요 내용", "기간"],
    ["1단계", "현황 분석 및 요구사항 정의", "11월"],
    ["2단계", "시스템 설계 및 개발", "12월 ~ 2월"],
    ["3단계", "시범 운영 및 개선", "3월"],
    ["4단계", "전사 확대 적용", "4월"],
])
para(doc)
heading(doc, "4. 소요 예산")
table(doc, [
    ["항목", "금액", "비고"],
    ["소프트웨어 라이선스", "4,500만 원", "연간"],
    ["시스템 개발", "8,000만 원", "외부 협력사"],
    ["교육 및 운영", "1,500만 원", "임직원 교육 포함"],
    ["합계", "1억 4,000만 원", ""],
])
para(doc)
heading(doc, "5. 기대 효과")
rich(doc, [("업무 효율 향상: ", True, BLUE), ("문서 검색 시간 70% 단축", False, None)])
rich(doc, [("비용 절감: ", True, BLUE), ("출력 및 보관 비용 연간 약 3,000만 원 절감", False, None)])
rich(doc, [("보안 강화: ", True, BLUE), ("문서 접근 이력 관리로 정보 유출 위험 감소", False, None)])
para(doc)
para(doc, "※ 본 문서는 앱 기능을 소개하기 위한 예시 문서입니다.", size=9, color=GRAY, italic=True)
doc.save(f"{OUT}/ProjectProposal.docx")

# ---------------------------------------------------------------- WorkManual
doc = Document()
para(doc, "신규 입사자를 위한", size=12, color=GRAY, align="center")
para(doc, "업무 매뉴얼", size=26, bold=True, color=NAVY, align="center")
para(doc, "ABC 주식회사 인사팀 · 2026년 개정판", size=11, color=GRAY, align="center")
para(doc)
heading(doc, "1. 근무 안내")
para(doc, "• 기본 근무 시간: 오전 9시 ~ 오후 6시 (점심시간 12시 ~ 1시)")
para(doc, "• 유연 근무: 오전 8시 ~ 10시 사이 출근 가능 (팀장 사전 승인)")
para(doc, "• 재택 근무: 주 1회, 업무 시스템에서 전날까지 신청")
para(doc)
heading(doc, "2. 문서 작성 규칙")
para(doc, "모든 공식 문서는 HWP 형식으로 작성하며, 아래 규칙을 따릅니다.")
para(doc, "1) 글꼴은 본문 11pt, 제목 16pt 이상을 사용합니다.")
para(doc, "2) 파일 이름은 ‘날짜_부서_문서명’ 형식으로 저장합니다. 예) 20261105_인사팀_교육계획")
para(doc, "3) 외부로 보내는 문서는 반드시 PDF로 변환하여 전달합니다.")
rich(doc, [("주의: ", True, RED), ("개인정보가 포함된 문서는 사내 메신저로 전송하지 마십시오.", False, None)])
para(doc)
heading(doc, "3. 보고 절차")
para(doc, "1) 담당자 초안 작성 → 2) 팀장 검토 → 3) 부서장 승인 → 4) 관련 부서 공유")
para(doc, "긴급 사안은 구두로 먼저 보고한 뒤, 당일 안에 서면 보고를 완료합니다.")
para(doc)
heading(doc, "4. 주요 연락처")
table(doc, [
    ["부서", "담당 업무", "내선 번호"],
    ["인사팀", "근태·급여·복리후생", "1201"],
    ["총무팀", "비품·시설·출입증", "1305"],
    ["IT지원팀", "계정·장비·보안", "1410"],
    ["재무팀", "경비 처리·법인카드", "1522"],
])
para(doc)
heading(doc, "5. 정보 보안 수칙")
para(doc, "• 자리를 비울 때는 반드시 화면 잠금(Windows + L)을 설정합니다.")
para(doc, "• 비밀번호는 90일마다 변경하며, 다른 사람과 공유하지 않습니다.")
para(doc, "• 출처가 불분명한 메일의 첨부 파일이나 링크는 열지 않습니다.")
para(doc, "• 업무 자료는 개인 클라우드나 USB에 저장하지 않습니다.")
rich(doc, [("보안 사고 신고: ", True, RED), ("IT지원팀 내선 1410 (24시간)", False, None)])
para(doc)
heading(doc, "6. 복리후생 안내")
table(doc, [
    ["항목", "내용", "신청 방법"],
    ["건강검진", "연 1회 종합검진 지원", "인사팀 공지 확인"],
    ["자기계발비", "월 10만 원 (도서·강의)", "업무 시스템 → 경비 신청"],
    ["경조사 지원", "경조금 및 경조 휴가", "인사팀에 증빙 제출"],
    ["동호회", "활동비 월 3만 원 지원", "총무팀에 등록"],
])
para(doc)
heading(doc, "7. 자주 묻는 질문")
rich(doc, [("Q. ", True, BLUE), ("연차는 언제부터 사용할 수 있나요?", True, None)])
para(doc, "A. 입사 후 1개월이 지나면 매월 1일씩 발생하며, 업무 시스템에서 신청할 수 있습니다.")
rich(doc, [("Q. ", True, BLUE), ("회사 노트북을 집에 가져갈 수 있나요?", True, None)])
para(doc, "A. 재택 근무일에 한해 가능하며, IT지원팀에 반출 신청을 해야 합니다.")
para(doc)
para(doc, "※ 본 문서는 앱 기능을 소개하기 위한 예시 문서입니다.", size=9, color=GRAY, italic=True)
doc.save(f"{OUT}/WorkManual.docx")
print("ok")
