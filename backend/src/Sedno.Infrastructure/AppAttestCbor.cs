using System.Buffers.Binary;
using System.Text;

namespace Sedno.Infrastructure;

// Small, bounded decoder for the definite-length CBOR subset used by App Attest.
// Rejects duplicate map keys, unsupported types, trailing data and excessive nesting.
internal sealed class AppAttestCbor(byte[] bytes)
{
    private int offset;
    public static Dictionary<object, object> Map(byte[] bytes)
    {
        var reader = new AppAttestCbor(bytes);
        var value = reader.Read(0) as Dictionary<object, object> ?? throw new FormatException();
        if (reader.offset != bytes.Length) throw new FormatException();
        return value;
    }
    private object Read(int depth)
    {
        if (depth > 8 || offset >= bytes.Length) throw new FormatException();
        var head = bytes[offset++];
        var major = head >> 5;
        var extra = head & 31;
        ulong length = extra switch
        {
            < 24 => (ulong)extra,
            24 => Take(1)[0],
            25 => BinaryPrimitives.ReadUInt16BigEndian(Take(2)),
            26 => BinaryPrimitives.ReadUInt32BigEndian(Take(4)),
            _ => throw new FormatException()
        };
        if (length > 65536) throw new FormatException();
        var n = (int)length;
        switch (major)
        {
            case 0: return (long)n;
            case 1: return -1L - n;
            case 2: return Take(n).ToArray();
            case 3: return new UTF8Encoding(false, true).GetString(Take(n));
            case 4:
                if (n > 32) throw new FormatException();
                var array = new object[n];
                for (var i = 0; i < n; i++) array[i] = Read(depth + 1);
                return array;
            case 5:
                if (n > 32) throw new FormatException();
                var map = new Dictionary<object, object>();
                for (var i = 0; i < n; i++)
                {
                    var key = Read(depth + 1);
                    if (key is not (string or long) || !map.TryAdd(key, Read(depth + 1))) throw new FormatException();
                }
                return map;
            default: throw new FormatException();
        }
    }
    private ReadOnlySpan<byte> Take(int count)
    {
        if (count < 0 || count > bytes.Length - offset) throw new FormatException();
        var result = bytes.AsSpan(offset, count);
        offset += count;
        return result;
    }
}
