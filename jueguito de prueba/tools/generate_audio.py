import wave, math, struct, random
from pathlib import Path
random.seed(42)
rate=22050
out=Path(__file__).resolve().parent.parent / 'audio'
out.mkdir(exist_ok=True)
def save(name,samples,loop=False):
    with wave.open(str(out/(name+'.wav')),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate)
        w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x))*26000)) for x in samples))
    if loop:
        (out/(name+'.wav.import')).write_text('[remap]\n\nimporter="wav"\ntype="AudioStreamWAV"\n\n[deps]\n\nsource_file="res://audio/'+name+'.wav"\n\n[params]\n\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\n')
beat=60/120
notes=[110,110,130.81,98,110,146.83,130.81,98]
samples=[]
for i in range(int(rate*16)):
    t=i/rate; b=t/beat; k=int(b); local=t%beat
    bass=notes[(k//2)%len(notes)]
    v=0.16*math.sin(2*math.pi*bass*t)*math.exp(-local*4)
    kick=0.38*math.sin(2*math.pi*(48*local+10*(1-math.exp(-local*35))))*math.exp(-local*18)
    hat=(random.random()*2-1)*math.exp(-(t%(beat/2))*100)*0.08
    snare=(random.random()*2-1)*math.exp(-local*25)*0.12 if k%2 else 0
    melody=[440,523.25,659.25,587.33,440,392,523.25,329.63][int(b*2)%8]
    lead=0.08*math.sin(2*math.pi*melody*t)*math.exp(-(t%(beat/2))*8)
    samples.append(v+kick+hat+snare+lead)
save('battle',samples,True)
for name,duration,start,end in [('warning',0.5,330,220),('freeze',0.8,1300,220),('climb',0.22,400,900),('hit',0.18,180,65),('hurt',0.25,120,40),('swing',0.12,800,100),('victory',1.3,440,880)]:
    samples=[]
    phase=0
    for i in range(int(rate*duration)):
        t=i/rate; f=start+(end-start)*t/duration;phase+=2*math.pi*f/rate
        v=math.sin(phase)*0.35*(1-t/duration)
        if name in ['hit','hurt','swing']:v+=(random.random()*2-1)*0.12*(1-t/duration)
        samples.append(v)
    save(name,samples)
