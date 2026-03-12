#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path
from datetime import datetime, timezone

OPENCLAW_HOME = Path.home() / ".openclaw"
PROJECTS_DIR = OPENCLAW_HOME / "workspace" / "projects"
PROJECT_JSON = PROJECTS_DIR / "project.json"
TMP_PROJECTS_DIR = PROJECTS_DIR / "tmp-projects"


def ensure_dirs():
    PROJECTS_DIR.mkdir(parents=True, exist_ok=True)
    TMP_PROJECTS_DIR.mkdir(parents=True, exist_ok=True)
    if not PROJECT_JSON.exists():
        PROJECT_JSON.write_text(json.dumps({"projects": {}}, indent=2))


def load_projects():
    ensure_dirs()
    return json.loads(PROJECT_JSON.read_text())


def save_projects(data):
    PROJECT_JSON.write_text(json.dumps(data, indent=2))


def create_project(name, project_type, description=""):
    data = load_projects()

    if name in data["projects"]:
        print(json.dumps({"error": f"Project {name} already exists"}))
        sys.exit(1)

    if project_type == "permanent":
        path = str(Path.home() / "workspace" / name)
    else:
        path = str(TMP_PROJECTS_DIR / name)

    data["projects"][name] = {
        "name": name,
        "path": path,
        "type": project_type,
        "createdAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "description": description,
    }

    save_projects(data)

    Path(path).mkdir(parents=True, exist_ok=True)

    if not (Path(path) / ".git").exists():
        os.system(f'cd "{path}" && git init')

    print(json.dumps(data["projects"][name]))


def list_projects(output_json=False):
    data = load_projects()
    if output_json:
        print(json.dumps(data["projects"]))
    else:
        for name, proj in data["projects"].items():
            print(f"{name}: {proj['type']} - {proj['description']}")


def get_project(name):
    data = load_projects()
    if name not in data["projects"]:
        print(json.dumps({"error": f"Project {name} not found"}))
        sys.exit(1)
    print(json.dumps(data["projects"][name]))


def delete_project(name):
    data = load_projects()
    if name not in data["projects"]:
        print(json.dumps({"error": f"Project {name} not found"}))
        sys.exit(1)

    del data["projects"][name]
    save_projects(data)
    print(json.dumps({"success": True}))


def cleanup_old_tmp():
    data = load_projects()
    now = datetime.now(timezone.utc)
    to_delete = []

    for name, proj in data["projects"].items():
        if proj["type"] == "temporary":
            created = datetime.fromisoformat(proj["createdAt"].replace("Z", ""))
            age_days = (now - created).days
            if age_days > 7:
                to_delete.append(name)

    for name in to_delete:
        del data["projects"][name]

    save_projects(data)
    print(json.dumps({"deleted": to_delete}))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: project-manager.py <command> [args]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "create":
        name = sys.argv[2]
        ptype = sys.argv[3]
        desc = sys.argv[4] if len(sys.argv) > 4 else ""
        create_project(name, ptype, desc)
    elif cmd == "list":
        list_projects("--json" in sys.argv)
    elif cmd == "get":
        get_project(sys.argv[2])
    elif cmd == "delete":
        delete_project(sys.argv[2])
    elif cmd == "cleanup":
        cleanup_old_tmp()
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
