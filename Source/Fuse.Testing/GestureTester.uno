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
		
		class TapGesture
		{
			readonly Element _element;
			readonly float2 _windowPoint;

			public TapGesture(Element element)
			{
				_element = element;
				_windowPoint = Vector.Transform(_element.ActualSize / 2, _element.WorldTransform).XY;
			}

			PointerEventData CreatePointerEventData()
			{
				return new PointerEventData
				{
					PointIndex = 0,
					WindowPoint = _windowPoint,
					IsPrimary = true,
					PointerType = Uno.Platform.PointerType.Touch,
					Timestamp = Time.FrameTime
				};
			}

			public void Perform()
			{
				Pointer.RaisePressed(_element, CreatePointerEventData());
				UpdateManager.PerformNextFrame(this.Release, UpdateStage.Primary);
			}

			void Release()
			{
				Pointer.RaiseReleased(_element, CreatePointerEventData());
			}
		}

		/**
			@scriptmethod tap(element)

			Simulates a tap gesture at the center of the bounds of a given @Element.

			**Note:** This only simulates taps at the window level.
			This means that if an element is in front of the target, the frontmost element will receive events instead.
		*/
		static object tap(Context c, object[] args)
		{
			var e = c.Wrap(args[0]) as Element;
			if (e == null)
			{
				throw new Exception("Argument must be an Element, got: " + args[0]);
			}
			
			UpdateManager.PostAction(new TapGesture(e).Perform);
			
			return null;
		}
	}
}
