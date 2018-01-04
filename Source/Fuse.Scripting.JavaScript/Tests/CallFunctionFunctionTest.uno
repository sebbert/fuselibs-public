using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class CallFunctionFunctionTest : TestBase
	{
		[Test]
		public void Basic1()
		{
			var e = new UX.CallFunctionFunction.Basic1();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				e.str1 = "Hello";
				e.str2 = "World";
				root.StepFrameJS();
				Assert.AreEqual("Hello World", e.result.StringValue);
			}
		}

		[Test]
		public void DiscardResult()
		{
			var e = new UX.CallFunctionFunction.DiscardResult();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				debug_log e.result.ObjectValue.GetType().FullName;
				Assert.AreEqual((double)400, e.result.UseValue);
				e.removeTheNumber.Perform();
				root.StepFrameJS();
				Assert.AreEqual(null, e.result.ObjectValue);
			}
		}
	}
}
