import numpy as np, wave, subprocess, sys, os
SR=48000
out=sys.argv[1]
def tone(f, dur, start=0, amp=0.5, decay=6.0, total=None):
    t=np.arange(int(SR*dur))/SR
    env=np.exp(-decay*t)*np.minimum(1, t/0.008)
    s=amp*env*(np.sin(2*np.pi*f*t)+0.25*np.sin(2*np.pi*2*f*t)+0.08*np.sin(2*np.pi*3*f*t))
    return int(SR*start), s
def mix(parts, length):
    buf=np.zeros(int(SR*length))
    for st,s in parts:
        e=min(len(buf), st+len(s)); buf[st:e]+=s[:e-st]
    # leve reverb: ecos amortecidos
    rev=np.copy(buf)
    for d,g in [(0.043,0.3),(0.071,0.22),(0.113,0.15),(0.167,0.1)]:
        k=int(SR*d); rev[k:]+=g*buf[:-k]
    rev/=max(1e-9, np.abs(rev).max())/0.7
    return rev
N=lambda n: 440*2**((n-69)/12)
sons={
 "notificacao": ([tone(N(81),0.6,0,0.5,7),tone(N(88),0.7,0.09,0.45,6)],0.9),
 "foco":        ([tone(N(69),1.2,0,0.4,3),tone(N(76),1.2,0.15,0.35,3),tone(N(81),1.4,0.3,0.35,2.5)],1.8),
 "desbloquear": ([tone(N(76),0.5,0,0.4,7),tone(N(83),0.6,0.07,0.4,6),tone(N(88),0.8,0.14,0.35,5)],1.0),
 "login":       ([tone(N(64),1.6,0,0.35,2),tone(N(71),1.6,0.12,0.3,2),tone(N(76),1.8,0.24,0.3,1.8),tone(N(83),2.0,0.36,0.25,1.6)],2.4),
 "erro":        ([tone(N(64),0.35,0,0.5,9),tone(N(60),0.45,0.12,0.5,8)],0.7),
 "captura":     ([tone(N(93),0.15,0,0.4,25),tone(N(98),0.2,0.05,0.35,20)],0.4),
 "conectar":    ([tone(N(72),0.4,0,0.4,8),tone(N(79),0.5,0.08,0.4,7)],0.7),
 "desconectar": ([tone(N(79),0.4,0,0.4,8),tone(N(72),0.5,0.08,0.4,7)],0.7),
 "bateria":     ([tone(N(76),0.4,0,0.45,8),tone(N(76),0.4,0.25,0.45,8)],0.8),
}
for name,(parts,L) in sons.items():
    a=(mix(parts,L)*32767).astype(np.int16)
    w=os.path.join(out,name+".wav")
    with wave.open(w,'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR); f.writeframes(a.tobytes())
    subprocess.run(["ffmpeg","-loglevel","error","-y","-i",w,"-c:a","libvorbis","-q:a","5",os.path.join(out,name+".ogg")],check=True)
    os.remove(w)
