import { useEffect, useRef, useState } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import "./architecture3d.css";

type Language = "de" | "en";
type FlowNode = { id: string; x: number; y: number; halfWidth: number; height: number; color: string; label: string; sublabel: string; lane: string };
type FlowEdge = { source: string; target: string; label: string; role: "observation" | "audio" | "token"; color: string };
type FlowModel = { title: string; nodes: FlowNode[]; edges: FlowEdge[]; lanes: Record<string, string>; legend: Record<string, string> };
type SceneActions = { reset: () => void; zoom: (factor: number) => void };

const MODEL_URL = "/visualizations/tiktok-live-companion-flow-model.json";
const FALLBACK_URL = "/visualizations/tiktok-live-companion-architecture.svg";

function labelSprite(node: FlowNode) {
  const canvas = document.createElement("canvas");
  canvas.width = 512; canvas.height = 128;
  const context = canvas.getContext("2d")!;
  context.fillStyle = "rgba(15, 23, 41, .88)";
  context.roundRect(4, 4, 504, 120, 18); context.fill();
  context.textAlign = "center"; context.fillStyle = "#ffffff";
  context.font = "700 32px Segoe UI, Arial"; context.fillText(node.label, 256, 52);
  context.fillStyle = "#d9e3ef"; context.font = "22px Segoe UI, Arial"; context.fillText(node.sublabel, 256, 90);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  const material = new THREE.SpriteMaterial({ map: texture, transparent: true, depthTest: false });
  const sprite = new THREE.Sprite(material);
  sprite.scale.set(2.9, .72, 1);
  sprite.position.set(node.x, node.height + .72, node.y);
  sprite.renderOrder = 4;
  return sprite;
}

function createArrow(edge: FlowEdge, nodes: Map<string, FlowNode>) {
  const source = nodes.get(edge.source)!;
  const target = nodes.get(edge.target)!;
  const start = new THREE.Vector3(source.x, source.height + .18, source.y);
  const end = new THREE.Vector3(target.x, target.height + .18, target.y);
  const middle = start.clone().lerp(end, .5); middle.y += .38;
  const curve = new THREE.QuadraticBezierCurve3(start, middle, end);
  const geometry = new THREE.BufferGeometry().setFromPoints(curve.getPoints(30));
  const material = edge.role === "token"
    ? new THREE.LineDashedMaterial({ color: edge.color, dashSize: .22, gapSize: .14 })
    : new THREE.LineBasicMaterial({ color: edge.color, linewidth: 2 });
  const line = new THREE.Line(geometry, material);
  if (edge.role === "token") line.computeLineDistances();
  line.userData.edge = edge;
  const tangent = curve.getTangent(1).normalize();
  const cone = new THREE.Mesh(new THREE.ConeGeometry(.10, .28, 12), new THREE.MeshBasicMaterial({ color: edge.color }));
  cone.position.copy(end.clone().sub(tangent.clone().multiplyScalar(.13)));
  cone.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), tangent);
  const group = new THREE.Group(); group.add(line, cone);
  return group;
}

export default function Architecture3D({ lang }: { lang: Language }) {
  const hostRef = useRef<HTMLDivElement>(null);
  const meshesRef = useRef<Map<string, THREE.Mesh>>(new Map());
  const actionsRef = useRef<SceneActions>({ reset: () => {}, zoom: () => {} });
  const [model, setModel] = useState<FlowModel | null>(null);
  const [ready, setReady] = useState(false);
  const [failed, setFailed] = useState(false);
  const [selected, setSelected] = useState(0);
  const de = lang === "de";

  useEffect(() => {
    let active = true;
    fetch(MODEL_URL).then(response => {
      if (!response.ok) throw new Error(`Model ${response.status}`);
      return response.json() as Promise<FlowModel>;
    }).then(data => { if (active) setModel(data); }).catch(() => { if (active) setFailed(true); });
    return () => { active = false; };
  }, []);

  useEffect(() => {
    if (!model || !hostRef.current) return;
    const host = hostRef.current;
    let renderer: THREE.WebGLRenderer;
    try { renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: "high-performance" }); }
    catch { setFailed(true); return; }
    renderer.setClearColor(0x0f1729, 1);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.domElement.setAttribute("aria-label", de ? "Interaktive 3D-Plattformarchitektur" : "Interactive 3D platform architecture");
    host.appendChild(renderer.domElement);

    const scene = new THREE.Scene();
    scene.fog = new THREE.Fog(0x0f1729, 16, 31);
    const camera = new THREE.PerspectiveCamera(42, 1, .1, 100);
    const defaultPosition = new THREE.Vector3(10.8, 10.2, 14.5);
    const target = new THREE.Vector3(4, .2, 0);
    camera.position.copy(defaultPosition);
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.target.copy(target); controls.enableDamping = true; controls.dampingFactor = .07;
    controls.minDistance = 7; controls.maxDistance = 28; controls.enablePan = false;
    controls.touches.ONE = THREE.TOUCH.ROTATE; controls.touches.TWO = THREE.TOUCH.DOLLY_ROTATE;

    scene.add(new THREE.HemisphereLight(0xdfeaff, 0x111827, 2.1));
    const key = new THREE.DirectionalLight(0xffffff, 2.4); key.position.set(-4, 10, 8); scene.add(key);
    const fill = new THREE.DirectionalLight(0xff7c9b, .8); fill.position.set(10, 5, -7); scene.add(fill);

    const laneColors: Record<string, number> = { browser: 0x0b5360, ios: 0x67233c, android: 0x18543d };
    for (const [lane, z] of [["browser", -2.4], ["ios", 0], ["android", 2.4]] as const) {
      const plane = new THREE.Mesh(new THREE.PlaneGeometry(9.5, 1.7), new THREE.MeshBasicMaterial({ color: laneColors[lane], transparent: true, opacity: .22, side: THREE.DoubleSide }));
      plane.rotation.x = -Math.PI / 2; plane.position.set(4, -.05, z); scene.add(plane);
    }

    const nodeMap = new Map(model.nodes.map(node => [node.id, node]));
    const pickable: THREE.Mesh[] = [];
    const meshes = new Map<string, THREE.Mesh>();
    for (const node of model.nodes) {
      const geometry = new THREE.BoxGeometry(node.halfWidth * 2, node.height, node.halfWidth * 2);
      const material = new THREE.MeshStandardMaterial({ color: node.color, roughness: .48, metalness: .08, emissive: new THREE.Color(node.color).multiplyScalar(.08) });
      const mesh = new THREE.Mesh(geometry, material);
      mesh.position.set(node.x, node.height / 2, node.y); mesh.userData.node = node; scene.add(mesh); pickable.push(mesh);
      meshes.set(node.id, mesh);
      scene.add(labelSprite(node));
    }
    meshesRef.current = meshes;
    for (const edge of model.edges) scene.add(createArrow(edge, nodeMap));

    const grid = new THREE.GridHelper(15, 15, 0x334155, 0x1e293b); grid.position.y = -.08; scene.add(grid);
    const raycaster = new THREE.Raycaster(); const pointer = new THREE.Vector2();
    const selectAt = (event: PointerEvent) => {
      const rect = renderer.domElement.getBoundingClientRect();
      pointer.set(((event.clientX - rect.left) / rect.width) * 2 - 1, -((event.clientY - rect.top) / rect.height) * 2 + 1);
      raycaster.setFromCamera(pointer, camera);
      const hit = raycaster.intersectObjects(pickable, false)[0];
      if (hit) setSelected(Math.max(0, model.nodes.findIndex(node => node.id === hit.object.userData.node.id)));
    };
    renderer.domElement.addEventListener("pointerup", selectAt);
    renderer.domElement.addEventListener("webglcontextlost", event => { event.preventDefault(); setFailed(true); setReady(false); });

    const reset = () => { camera.position.copy(defaultPosition); controls.target.copy(target); controls.update(); };
    const zoom = (factor: number) => { camera.position.sub(controls.target).multiplyScalar(factor).add(controls.target); controls.update(); };
    actionsRef.current = { reset, zoom };
    const onKey = (event: KeyboardEvent) => {
      if (["Escape", "r", "R"].includes(event.key)) reset();
      if (event.key === "+" || event.key === "=") zoom(.86);
      if (event.key === "-") zoom(1.16);
      if (event.key.startsWith("Arrow")) {
        event.preventDefault();
        const offset = camera.position.clone().sub(controls.target);
        const angle = event.key === "ArrowLeft" ? .12 : event.key === "ArrowRight" ? -.12 : 0;
        if (angle) offset.applyAxisAngle(new THREE.Vector3(0, 1, 0), angle);
        if (event.key === "ArrowUp") offset.y += .5;
        if (event.key === "ArrowDown") offset.y -= .5;
        camera.position.copy(controls.target.clone().add(offset)); controls.update();
      }
    };
    host.addEventListener("keydown", onKey);

    const resize = () => {
      const width = Math.max(320, host.clientWidth); const height = Math.max(420, host.clientHeight);
      renderer.setSize(width, height, false); camera.aspect = width / height; camera.updateProjectionMatrix();
    };
    const observer = new ResizeObserver(resize); observer.observe(host); resize();
    let frame = 0; let visible = !document.hidden; let firstFrame = true;
    const visibility = () => { visible = !document.hidden; };
    document.addEventListener("visibilitychange", visibility);
    const animate = () => { frame = requestAnimationFrame(animate); if (!visible) return; controls.update(); renderer.render(scene, camera); if (firstFrame) { firstFrame = false; setReady(true); } };
    animate();

    return () => {
      cancelAnimationFrame(frame); observer.disconnect(); document.removeEventListener("visibilitychange", visibility);
      host.removeEventListener("keydown", onKey); renderer.domElement.removeEventListener("pointerup", selectAt); controls.dispose();
      scene.traverse(object => {
        if (object instanceof THREE.Mesh || object instanceof THREE.Line) object.geometry.dispose();
        if (object instanceof THREE.Mesh || object instanceof THREE.Line || object instanceof THREE.Sprite) {
          const materials = Array.isArray(object.material) ? object.material : [object.material];
          materials.forEach(material => { if (material instanceof THREE.SpriteMaterial) material.map?.dispose(); material.dispose(); });
        }
      });
      renderer.dispose(); renderer.domElement.remove(); actionsRef.current = { reset: () => {}, zoom: () => {} };
      meshesRef.current = new Map();
    };
  }, [model, de]);

  useEffect(() => {
    if (!model) return;
    for (const [id, mesh] of meshesRef.current) {
      const material = mesh.material as THREE.MeshStandardMaterial;
      const active = model.nodes[selected]?.id === id;
      material.emissiveIntensity = active ? 1.6 : 1;
      mesh.scale.setScalar(active ? 1.08 : 1);
    }
  }, [model, selected, ready]);

  const node = model?.nodes[selected];
  const step = (delta: number) => { if (model) setSelected((selected + delta + model.nodes.length) % model.nodes.length); };
  return <main className="architecture-3d-page">
    <header className="architecture-3d-header"><a href={`/${lang}`}>TikTok <b>LIVE</b> Companion</a><nav><a href={`/${lang}/architecture`}>{de ? "← Architektur" : "← Architecture"}</a><a href={`/${lang === "de" ? "en" : "de"}/architecture-3d`}>{lang === "de" ? "EN" : "DE"}</a></nav></header>
    <section className="architecture-3d-intro"><p className="architecture-3d-eyebrow">THREE.JS · 0.7.0</p><h1>{de ? "Interaktive Plattformarchitektur" : "Interactive platform architecture"}</h1><p>{de ? "Drehen, zoomen und Knoten auswählen. Tiefe trennt Browser, iOS und Android/HyperOS; alle Pfade stammen aus demselben reproduzierbaren Projektmodell wie SVG und GIF." : "Orbit, zoom, and select nodes. Depth separates browser, iOS, and Android/HyperOS; every path uses the same reproducible project model as SVG and GIF."}</p></section>
    <section className="architecture-3d-workspace">
      <div className="architecture-3d-scene-shell">
        {(!ready || failed) && <img className="architecture-3d-fallback" src={FALLBACK_URL} alt={de ? "Statische Plattformarchitektur mit Browser-, iOS- und Android-Pfaden" : "Static platform architecture with browser, iOS, and Android paths"}/>} 
        <div className={`architecture-3d-scene ${ready && !failed ? "is-ready" : ""}`} ref={hostRef} tabIndex={0}/>
        <div className="architecture-3d-controls" aria-label={de ? "3D-Ansicht steuern" : "Control 3D view"}><button onClick={() => actionsRef.current.zoom(.86)}>＋</button><button onClick={() => actionsRef.current.zoom(1.16)}>−</button><button onClick={() => actionsRef.current.reset()}>{de ? "Zurücksetzen" : "Reset"}</button></div>
      </div>
      <aside className="architecture-3d-inspector" aria-live="polite"><p className="architecture-3d-eyebrow">{de ? "AUSGEWÄHLTER KNOTEN" : "SELECTED NODE"}</p><h2>{node?.label ?? (de ? "Modell wird geladen" : "Loading model")}</h2><p>{node?.sublabel}</p><dl><div><dt>{de ? "Plattform" : "Platform"}</dt><dd>{node ? model?.lanes[node.lane] ?? "Gemeinsam" : "–"}</dd></div><div><dt>ID</dt><dd>{node?.id ?? "–"}</dd></div></dl><div className="architecture-3d-step"><button onClick={() => step(-1)}>{de ? "← Vorheriger" : "← Previous"}</button><button onClick={() => step(1)}>{de ? "Nächster →" : "Next →"}</button></div></aside>
    </section>
    <section className="architecture-3d-legend"><span><i className="observation"/>{de ? "Passive Beobachtung" : "Passive observation"}</span><span><i className="audio"/>{de ? "Audio nur nach Klick" : "Audio only after click"}</span><span><i className="token"/>{de ? "Kurzlebiges ES256-Token" : "Short-lived ES256 token"}</span></section>
    <p className="architecture-3d-note">{de ? "Schematische Dokumentationsansicht – Boxgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie und keine Remote-Daten." : "Schematic documentation view—box sizes measure neither data volume nor performance. No telemetry or remote data."}</p>
  </main>;
}
