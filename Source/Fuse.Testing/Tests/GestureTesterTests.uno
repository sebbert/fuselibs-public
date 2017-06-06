using Uno;
using Uno.Testing;
using FuseTest;
using Fuse.Testing;
using Fuse.Input;
using Fuse.Input.UX;

namespace Fuse.Testing.Test
{
	public class GestureTesterTests : TestBase
	{
		class PressedStateListener : IDisposable
		{
			public bool IsPressed { get; private set; }

			Visual _target;

			public PressedStateListener(Visual v)
			{
				_target = v;
				Pointer.Pressed.AddHandler(_target, OnPressed);
				Pointer.Released.AddHandler(_target, OnReleased);
			}

			public void Dispose()
			{
				Pointer.Pressed.RemoveHandler(_target, OnPressed);
				Pointer.Released.RemoveHandler(_target, OnReleased);
			}

			void OnPressed(object sender, PointerPressedArgs args)
			{
				IsPressed = true;
			}

			void OnReleased(object sender, PointerReleasedArgs args)
			{
				IsPressed = false;
			}
		}

		[Test]
		public void PressReleaseOnSeparateFrames()
		{
			new GestureTester();
			var e = new UX.GestureTester();
			var root = FuseTest.TestRootPanel.CreateWithChild(e);
			var target = e.target;

			using(var pressed = new PressedStateListener(e))
			{
				GestureTester.Tap(target);

				Assert.IsTrue(pressed.IsPressed);
				root.CompleteNextFrame();
				Assert.IsFalse(pressed.IsPressed);
			}
		}
	}
}
