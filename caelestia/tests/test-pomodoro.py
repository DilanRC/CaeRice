import importlib.util, tempfile, time
from importlib.machinery import SourceFileLoader
from pathlib import Path
spec=importlib.util.spec_from_loader("p", SourceFileLoader("p", str(Path(__file__).parents[1]/"bin/caerice-pomodoro"))); p=importlib.util.module_from_spec(spec); spec.loader.exec_module(p)
with tempfile.TemporaryDirectory() as d:
    p.path=lambda: Path(d)/"pomodoro.json"
    s=p.load(); assert s["phase"]=="IDLE"
    now=1000; s["phase"]="FOCUS"; s["targetEndTimestamp"]=now+1; s=p.advance(s, now+2); assert s["phase"]=="BREAK"
    s["phase"]="FOCUS"; s["targetEndTimestamp"]=now+1; s=p.advance(s, now+2); assert s["completedSessions"]==2
    s["phase"]="FOCUS"; s["targetEndTimestamp"]=2000; p.save(s); s["pausedRemainingMs"]=1234; s["phase"]="PAUSED"; p.save(s); assert p.load()["pausedRemainingMs"]==1234
    s={**p.DEFAULT, "phase":"BREAK", "targetEndTimestamp":2000}; p.save(s); s=p.load(); now=1000; s["pausedRemainingMs"]=9000; s["pausedPhase"]=s["phase"]; s["phase"]="PAUSED"; p.save(s); s=p.load(); s["phase"]=s["pausedPhase"]; assert s["phase"]=="BREAK"
    assert p.event_path().name == "pomodoro-notification.json"
print("PASS: Pomodoro timestamp transitions, persistence, and restart-safe state")
