import os
import re
from pathlib import Path

def get_web_endpoints():
    api_ts_path = Path("frontend/cash-deposit-portal/src/api.ts")
    content = api_ts_path.read_text(encoding="utf-8")
    
    # Extract method and endpoint from fetch calls
    pattern = re.compile(r"fetch\([`'\"]\$\{API_BASE\}([^`'\"?]+)(?:\?[^`'\"]*)?[`'\"](?:,\s*\{([^}]*)\})?", re.DOTALL)
    
    calls = []
    for match in pattern.finditer(content):
        endpoint = match.group(1).strip()
        # Clean up any trailing template variables like ${query}
        endpoint = re.sub(r"\$\{query\}", "", endpoint)
        options = match.group(2) or ""
        method = "GET"
        method_match = re.search(r"method:\s*['\"]([A-Z]+)['\"]", options)
        if method_match:
            method = method_match.group(1)
        calls.append((method, endpoint))
    return calls

def get_gateway_routes():
    yml_path = Path("backend/services/api-gateway/src/main/resources/application.yml")
    lines = yml_path.read_text().splitlines()
    routes = []
    curr_id = None
    curr_uri = None
    curr_paths = []
    
    in_routes = False
    for line in lines:
        if "routes:" in line:
            in_routes = True
            continue
        if not in_routes:
            continue
        id_m = re.match(r"\s*-\s*id:\s*(\S+)", line)
        if id_m:
            if curr_id:
                routes.append({"id": curr_id, "uri": curr_uri, "paths": curr_paths})
            curr_id = id_m.group(1)
            curr_uri = None
            curr_paths = []
            continue
        uri_m = re.match(r"\s*uri:\s*(\S+)", line)
        if uri_m:
            curr_uri = uri_m.group(1)
            continue
        path_m = re.match(r"\s*-\s*Path=(.+)", line)
        if path_m:
            curr_paths.extend([p.strip() for p in path_m.group(1).split(",")])
            
    if curr_id:
        routes.append({"id": curr_id, "uri": curr_uri, "paths": curr_paths})
    return routes

def find_matching_route(endpoint, routes):
    norm_ep = re.sub(r"\$\{[^}]+\}", "12345", endpoint).rstrip("/")
    for r in routes:
        for p in r["paths"]:
            p = p.strip()
            # In Spring Cloud Gateway:
            # - /api/v1/foo/** matches /api/v1/foo/bar, but might NOT match /api/v1/foo if without trailing slash
            # Exact match check
            if p == norm_ep:
                return r
            if p.endswith("/**"):
                base = p[:-3]
                if norm_ep.startswith(base + "/"):
                    return r
                # NOTE: Spring Cloud Gateway Path=/api/v1/foo/** only matches paths with subpaths!
            elif p.endswith("/*"):
                base = p[:-2]
                if norm_ep.startswith(base + "/") and "/" not in norm_ep[len(base)+1:]:
                    return r
    return None

def scan_controllers():
    controllers = {}
    base_dir = Path("backend/services")
    for java_file in base_dir.glob("**/*.java"):
        if "target" in java_file.parts or "test" in java_file.parts:
            continue
        content = java_file.read_text(encoding="utf-8")
        if "@RestController" not in content:
            continue
            
        class_rm = re.findall(r"@RequestMapping\(\s*(?:value\s*=\s*)?[\"']([^\"']+)[\"']", content)
        base_path = class_rm[0] if class_rm else ""
        
        method_mappings = re.findall(r"@(Get|Post|Put|Delete|Patch)Mapping(?:\(\s*(?:value\s*=\s*)?(?:\{([^}]+)\}|[\"']([^\"']+)[\"'])?)?", content)
        for mm in method_mappings:
            http_verb = mm[0].upper()
            subpaths = []
            if mm[1]:
                subpaths = [s.strip().strip("\"'") for s in mm[1].split(",")]
            elif mm[2]:
                subpaths = [mm[2].strip()]
            else:
                subpaths = [""]
                
            for sp in subpaths:
                full_path = (base_path + ("" if sp.startswith("/") or not sp else "/") + sp).rstrip("/")
                if not full_path:
                    full_path = "/"
                controllers[(http_verb, full_path, java_file.name)] = java_file
    return controllers

def match_controller(verb, endpoint, controllers):
    norm_ep = re.sub(r"\$\{[^}]+\}", "{var}", endpoint).rstrip("/")
    for (ctrl_verb, ctrl_path, filename), filepath in controllers.items():
        if verb != ctrl_verb:
            continue
        pattern = "^" + re.sub(r"\{[^}]+\}", "[^/]+", ctrl_path) + "$"
        norm_for_match = re.sub(r"\{var\}", "DUMMY", norm_ep)
        if re.match(pattern, norm_for_match):
            return filename, ctrl_path, filepath
    return None

def main():
    web_calls = get_web_endpoints()
    gateway_routes = get_gateway_routes()
    controllers = scan_controllers()
    
    print(f"Loaded {len(gateway_routes)} gateway routes.")
    print(f"Loaded {len(controllers)} controller method mappings across all @RestController classes.")
    print(f"Auditing {len(web_calls)} API calls from frontend/cash-deposit-portal/src/api.ts...\n")
    
    missing_routes = []
    missing_controllers = []
    success_count = 0
    
    for verb, ep in web_calls:
        if ep == "${endpointUrl}":
            continue
        
        route = find_matching_route(ep, gateway_routes)
        ctrl_match = match_controller(verb, ep, controllers)
        
        if not route:
            missing_routes.append((verb, ep))
        if not ctrl_match:
            missing_controllers.append((verb, ep, route["uri"] if route else "NO_ROUTE"))
        else:
            success_count += 1
            
    print(f"Results: {success_count} calls VERIFIED OK.")
    if missing_routes:
        print(f"\n[!] POTENTIAL GATEWAY ROUTING ISSUES ({len(missing_routes)}):")
        for verb, ep in missing_routes:
            print(f"  - {verb} {ep}")
    else:
        print("\n[+] All Web endpoints are safely routed by API Gateway! 100% COVERAGE.")
        
    if missing_controllers:
        print(f"\n[!] MISSING BACKEND CONTROLLER ENDPOINTS ({len(missing_controllers)}):")
        for verb, ep, route in missing_controllers:
            print(f"  - {verb:<6} {ep:<50} (Target route: {route})")
    else:
        print("\n[+] All Web endpoints have matching Backend Controller implementations! 100% COVERAGE.")

if __name__ == "__main__":
    main()
