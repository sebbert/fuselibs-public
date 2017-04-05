using Uno;
using Uno.UX;
using Fuse;
using Fuse.Input;
using Fuse.Scripting;
using Fuse.Elements;

namespace Fuse.Testing
{
	[UXGlobalModule]
	public class GestureTester : NativeModule
	{
	    static readonly GestureTester _instance;

	    public GestureTester()
	    {
	        // Make sure we're only initializing the module once
	        if (_instance != null) return;

	        _instance = this;
	        Resource.SetGlobalKey(_instance, "FuseJS/GestureTester");
	        AddMember(new NativeFunction("tap", (NativeCallback)tap));
	    }

		class Gesture
		{
			readonly Element _element;
			public Gesture(Element elm) 
			{
				_element = elm;
			}
			public void Tap() 
			{
				var p = Vector.Transform(_element.ActualSize / 2, _element.WorldTransform).XY;

				var press = new PointerEventData() {
					PointIndex = 0,
					WindowPoint = p,
					IsPrimary = true,
					PointerType = Uno.Platform.PointerType.Touch,
					Timestamp = Time.FrameTime
				};

				Pointer.RaisePressed(_element, press);

				var release = new PointerEventData() {
					PointIndex = 0,
					WindowPoint = p,
					IsPrimary = true,
					PointerType = Uno.Platform.PointerType.Touch,
					Timestamp = Time.FrameTime + 0.30
				};

				Pointer.RaiseReleased(_element, release);
			}
		}

	    static object tap(Context c, object[] args)
	    {
	    	var e = c.Wrap(args[0]) as Element;
	    	if (e == null) throw new Exception("Argument must be an Element, got: " + args[0]);
	        UpdateManager.PostAction(new Gesture(e).Tap);
	        return null;
	    }
	}
}