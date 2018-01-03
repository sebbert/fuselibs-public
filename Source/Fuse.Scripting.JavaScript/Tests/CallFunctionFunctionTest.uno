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
		public void InvalidFunction()
		{
			var e = new UX.CallFunctionFunction.InvalidFunction();
			using (var diag = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				var diagnostics = diag.DequeueAll();
				Assert.Contains("not a function", diagnostics[0].Message);
			}
		}
	}
}
