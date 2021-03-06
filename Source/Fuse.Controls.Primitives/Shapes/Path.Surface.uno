using Uno;
using Uno.Collections;

using Fuse.Drawing;

namespace Fuse.Controls
{
	public partial class Path
	{
		protected override bool NeedSurface { get { return true; } }
		
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			var pos = CalcPositioning();
			
			var list = new List<LineSegment>();
			for (int i=0; i < _segments.Count; ++i )
			{
				var seg = _segments[i];
				seg.Translate( -pos.Extents.Minimum );
				seg.Scale( pos.Scale );
				seg.Translate( pos.Offset + pos.Extents.Minimum );
				list.Add(seg);
			}
			
			return surface.CreatePath(list, FillRule);
		}
	}
}
