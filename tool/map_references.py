from playwright.sync_api import sync_playwright
from pathlib import Path
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True)
    page=browser.new_page(viewport={"width":1400,"height":1000},locale="en-US")
    for name,url in [("tunis","https://www.google.com/maps/@36.7999,10.186,18z/data=!3m1!1e3"),("lucca","https://www.google.com/maps/@43.8451,10.5063,19z/data=!3m1!1e3")]:
        try:
            page.goto(url,wait_until="domcontentloaded",timeout=45000)
            page.wait_for_timeout(2500)
            for label in ["Reject all", "Tout refuser"]:
                button=page.get_by_role("button",name=label,exact=True)
                if button.count(): button.first.click();page.wait_for_timeout(1500)
            page.wait_for_timeout(5000)
            page.screenshot(path=f"docs/references/v9/google-{name}.png")
            Path(f"docs/references/v9/google-{name}.txt").write_text(page.inner_text("body")[:12000],encoding="utf-8")
            print(name,page.title(),page.url)
        except Exception as e: print(name,str(e)[:400])
    browser.close()
