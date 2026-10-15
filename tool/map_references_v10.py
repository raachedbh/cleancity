from playwright.sync_api import sync_playwright
from pathlib import Path
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True)
    page=browser.new_page(viewport={"width":1400,"height":1000},locale="en-US")
    for name,url in [('lucca', 'https://www.google.com/maps/@43.8451,10.5063,18z/data=!3m1!1e3'), ('paris', 'https://www.google.com/maps/@48.8556,2.3655,18z/data=!3m1!1e3'), ('kyoto', 'https://www.google.com/maps/@35.0058,135.7746,18z/data=!3m1!1e3'), ('burford', 'https://www.google.com/maps/@51.8076,-1.6367,18z/data=!3m1!1e3'), ('rothenburg', 'https://www.google.com/maps/@49.3777,10.1789,18z/data=!3m1!1e3')]:
        try:
            page.goto(url,wait_until="domcontentloaded",timeout=45000)
            page.wait_for_timeout(2500)
            for label in ["Reject all", "Tout refuser"]:
                button=page.get_by_role("button",name=label,exact=True)
                if button.count(): button.first.click();page.wait_for_timeout(1500)
            page.wait_for_timeout(5000)
            page.screenshot(path=f"docs/references/v10/google-{name}.png")
            Path(f"docs/references/v10/google-{name}.txt").write_text(page.inner_text("body")[:12000],encoding="utf-8")
            print(name,"saved")
        except Exception as e: print(name,str(e)[:400])
    browser.close()
