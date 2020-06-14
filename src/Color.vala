public class Color {
    public uint8 a { get; set; }
    public uint8 r { get; set; }
    public uint8 g { get; set; }
    public uint8 b { get; set; }
  
    public Color (uint8 r, uint8 g, uint8 b, uint8 a) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }
}
