#!/usr/bin/env python3
"""Place baby-remote footprints on the PCB at the SCAD button grid (pcbnew).
Self-contained + schematic-parity clean: "/NAME" nets, FPIDs with library
nickname, footprints linked to symbols by UUID."""
import pcbnew, json, os

HERE = os.path.dirname(os.path.abspath(__file__))
KFP  = "/Applications/KiCad/KiCad.app/Contents/SharedSupport/footprints"
SW_LIB, LED_LIB = f"{KFP}/Button_Switch_THT.pretty", f"{KFP}/LED_SMD.pretty"
C3_LIB = f"{HERE}/footprints/ESP32-C3-SuperMini.pretty"
def mm(v): return pcbnew.FromMM(v)
def xy(x,y): return pcbnew.VECTOR2I(mm(x),mm(y))

SY=json.load(open(f"{HERE}/symbols.json")); ROOT=SY["root"]; REFS=SY["refs"]
board=pcbnew.LoadBoard(f"{HERE}/baby-remote.kicad_pcb")

netnames=["/ROW0","/ROW1","/ROW2","/ROW3","/COL0","/COL1","/COL2","/COL3",
          "/LED_DIN","/+3V3","/+5V","/GND"]
nets={}
for nm in netnames:
    n=board.FindNet(nm)
    if n is None: n=pcbnew.NETINFO_ITEM(board,nm); board.Add(n)
    nets[nm]=n

def add_fp(libdir,libnick,name,ref,val,x,y):
    fp=pcbnew.FootprintLoad(libdir,name)
    if fp is None: raise SystemExit(f"missing fp {name}")
    fp.SetFPID(pcbnew.LIB_ID(libnick,name)); fp.SetReference(ref); fp.SetValue(val)
    fp.Value().SetVisible(True)
    fp.Value().SetPosition(pcbnew.VECTOR2I(mm(x+3.25), mm(y+7.5)))
    fp.SetPosition(xy(x,y))
    if ref in REFS: fp.SetPath(pcbnew.KIID_PATH(f"/{ROOT}/{REFS[ref]}"))
    board.Add(fp); return fp

def net_pad(fp,num,net):
    if net not in nets: return
    for p in fp.Pads():
        if p.GetNumber()==num: p.SetNet(nets[net])

LAB=[["Breast","Bottle","Solid","Sleep"],["PumpL","PumpR","Bath","Meds"],
     ["Pee","Poop","Both","Change"],["Tummy","Weight","Note","LED"]]
n=1
for r in range(4):
    for c in range(4):
        x,y=16.5+17*c,38.5+17*r
        if r==3 and c==3:
            led=add_fp(LED_LIB,"LED_SMD","LED_WS2812B_PLCC4_5.0x5.0mm_P3.2mm","LED1","WS2812B",x,y)
            net_pad(led,"1","/+5V"); net_pad(led,"3","/GND"); net_pad(led,"4","/LED_DIN"); continue
        sw=add_fp(SW_LIB,"Button_Switch_THT","SW_PUSH_6mm_H13mm",f"SW{n}",LAB[r][c],x,y)
        net_pad(sw,"1",f"/ROW{r}"); net_pad(sw,"2",f"/COL{c}"); n+=1

u1=add_fp(C3_LIB,"ESP32-C3-SuperMini","MODULE_ESP32-C3_SUPERMINI","U1","ESP32-C3 SuperMini",66,14)
for pad,net in {"0":"/ROW0","1":"/ROW1","3":"/ROW2","4":"/ROW3","5":"/COL0","6":"/COL1",
                "7":"/COL2","10":"/COL3","8":"/LED_DIN","3.3":"/+3V3","5V":"/+5V","G":"/GND"}.items():
    net_pad(u1,pad,net)


for ref,padnum,pin in [("LED1","2","DOUT"),("U1","2","GPIO2"),("U1","9","GPIO9"),("U1","20","GPIO20"),("U1","21","GPIO21")]:
    fp=board.FindFootprintByReference(ref); nn=f"unconnected-({ref}-{pin}-Pad{padnum})"
    ni=board.FindNet(nn)
    if ni is None: ni=pcbnew.NETINFO_ITEM(board,nn); board.Add(ni)
    for p in fp.Pads():
        if p.GetNumber()==padnum: p.SetNet(ni)

rect=[(2,2),(82,2),(82,104),(2,104),(2,2)]
for (x1,y1),(x2,y2) in zip(rect,rect[1:]):
    s=pcbnew.PCB_SHAPE(board); s.SetShape(pcbnew.SHAPE_T_SEGMENT)
    s.SetStart(xy(x1,y1)); s.SetEnd(xy(x2,y2)); s.SetLayer(pcbnew.Edge_Cuts); s.SetWidth(mm(0.15))
    board.Add(s)
board.BuildListOfNets(); pcbnew.SaveBoard(f"{HERE}/baby-remote.kicad_pcb",board)
print(f"placed {n-1} switches + LED + C3")
