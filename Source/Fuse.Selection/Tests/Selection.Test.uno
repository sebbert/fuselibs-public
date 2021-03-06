using Uno;
using Uno.Testing;

using FuseTest;
using Fuse.Selection;

namespace Fuse.Gestures.Test
{
	public class SelectionTests : TestBase
	{
		[Test]
		/* Using Min/MaxCount==1 */
		public void RadioButton()
		{	
			var p = new UX.RadioButton();
			var root = TestRootPanel.CreateWithChild(p);
			
			Assert.AreEqual("", p.TS.Value);
			Assert.AreEqual(float4(0), p.I1.Color);

			p.I1.SelAct.Pulse();
			root.StepFrame();
			Assert.AreEqual("one", p.TS.Value);
			Assert.AreEqual(float4(1), p.I1.Color);
			
			p.I2.SelAct.Pulse();
			root.StepFrame();
			Assert.AreEqual("two", p.TS.Value);
			Assert.AreEqual(float4(0), p.I1.Color);
			Assert.AreEqual(float4(1), p.I2.Color);
		}
		
		[Test]
		/* Rename a value (primarily to test JS binding on the name) and some various changes in selection */
		public void ChangeSelectableValue()
		{
			var p = new UX.ChangeSelectableValue();
			var root = TestRootPanel.CreateWithChild(p);
			
			Assert.AreEqual(0, p.TS.SelectedCount);
			
			p.TS.Toggle(p.I1.Sel);
			Assert.AreEqual(1, p.TS.SelectedCount);
			Assert.IsTrue(p.TS.IsSelected(p.I1.Sel));
			Assert.IsFalse(p.TS.IsSelected(p.I2.Sel));

			//rename
			p.I1.Value = "pone";
			Assert.AreEqual(1, p.TS.SelectedCount);
			Assert.AreEqual("pone", p.TS.Value);
			Assert.IsTrue(p.TS.IsSelected(p.I1.Sel));
			Assert.IsFalse(p.TS.IsSelected(p.I2.Sel));
			
			p.TS.Add(p.I2.Sel);
			Assert.AreEqual(2, p.TS.SelectedCount);
			Assert.IsTrue(p.TS.IsSelected(p.I1.Sel));
			Assert.IsTrue(p.TS.IsSelected(p.I2.Sel));
			
			//rename
			p.I2.Value = "ptwo";
			Assert.AreEqual(2, p.TS.SelectedCount);
			Assert.IsTrue(p.TS.IsSelected(p.I1.Sel));
			Assert.IsTrue(p.TS.IsSelected(p.I2.Sel));
			
			p.TS.Remove(p.I3.Sel);
			Assert.AreEqual(2, p.TS.SelectedCount);
			
			p.TS.Toggle(p.I1.Sel);
			Assert.AreEqual(1, p.TS.SelectedCount);
			Assert.IsFalse(p.TS.IsSelected(p.I1.Sel));
			Assert.IsTrue(p.TS.IsSelected(p.I2.Sel));
		}
		
		[Test]
		public void Replace()
		{
			var p = new UX.Replace();
			var root = TestRootPanel.CreateWithChild(p);
			
			Assert.AreEqual("", p.TS.Test_JoinValues() );

			//Oldest is the default Replace mode
			p.TS.Add(p.I1.Sel);
			p.TS.Add(p.I3.Sel);
			p.TS.Add(p.I2.Sel);
			//not yet guaranteed, but order should be oldest to newest
			Assert.AreEqual("three,two", p.TS.Test_JoinValues() );
			
			
			p.TS.Replace = SelectionReplace.Newest;
			p.TS.Add(p.I4.Sel);
			Assert.AreEqual("three,four", p.TS.Test_JoinValues() );
			p.TS.Add(p.I1.Sel);
			Assert.AreEqual("three,one", p.TS.Test_JoinValues() );
			
			
			p.TS.Replace = SelectionReplace.None;
			p.TS.Add(p.I4.Sel);
			Assert.AreEqual("three,one", p.TS.Test_JoinValues() );
		}
		
		[Test]
		/* Tests the Values binding to an Observable */
		public void Values()
		{
			var p = new UX.Values();
			var root = TestRootPanel.CreateWithChild(p);
			
			root.StepFrameJS();
			Assert.AreEqual("two,four", p.C.Value);
			
			p.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one,two,four", p.C.Value);
			Assert.AreEqual("one,two,four", p.TS.Test_JoinValues() );
			
			p.CallReplace.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one,five,four", p.C.Value);
			Assert.AreEqual("one,five,four", p.TS.Test_JoinValues() );
			
			p.TS.Toggle(p.O5.Sel);
			root.StepFrameJS();
			Assert.AreEqual("one,four", p.C.Value);
			
			p.CallRemove.Perform();
			root.StepFrameJS();
			Assert.AreEqual("four", p.C.Value);
			Assert.AreEqual("four", p.TS.Test_JoinValues() );
			
			p.TS.Remove(p.O4.Sel);
			root.StepFrameJS();
			Assert.AreEqual("", p.C.Value);
			
			p.TS.Value = "three";
			root.StepFrameJS();
			Assert.AreEqual("three", p.C.Value);
			
			p.CallSet.Perform();
			root.StepFrameJS();
			Assert.AreEqual("two", p.C.Value);
		}
		
		[Test]
		/* Test the Selection JS script class interface */
		public void JsSelection()
		{
			var p = new UX.JsSelection();
			var root = TestRootPanel.CreateWithChild(p);
			
			Assert.AreEqual("two", p.TS.Test_JoinValues());
			
			p.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual("two,one", p.TS.Test_JoinValues());
			
			//no change
			p.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual("two,one", p.TS.Test_JoinValues());
			
			p.CallRemove.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one", p.TS.Test_JoinValues());
			
			//safe to remove items not in list
			p.CallRemove.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one", p.TS.Test_JoinValues());
			
			p.CallToggle.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one,three", p.TS.Test_JoinValues());
			
			p.CallToggle.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one", p.TS.Test_JoinValues());
			
			p.CallClear.Perform();
			root.StepFrameJS();
			Assert.AreEqual("", p.TS.Test_JoinValues());
		}
		
		[Test]
		/* Test the Selectable JS script class interface.*/
		public void JsSelectable()
		{
			var p = new UX.JsSelectable();
			var root = TestRootPanel.CreateWithChild(p);
			
			Assert.AreEqual("two", p.TS.Test_JoinValues());
			
			p.O1.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual("two,one", p.TS.Test_JoinValues());
			
			//no change
			p.O1.CallAdd.Perform();
			root.StepFrameJS();
			Assert.AreEqual("two,one", p.TS.Test_JoinValues());
			
			p.O2.CallRemove.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one", p.TS.Test_JoinValues());
			
			//safe to remove items not in list
			p.O2.CallRemove.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one", p.TS.Test_JoinValues());
			
			p.O3.CallToggle.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one,three", p.TS.Test_JoinValues());
			
			p.O3.CallToggle.Perform();
			root.StepFrameJS();
			Assert.AreEqual("one", p.TS.Test_JoinValues());
		}
		
		[Test]
		/* Tests JS interface limits and forced options */
		public void JsSelectionLimit()
		{
			var p = new UX.JsSelectionLimit();
			var root = TestRootPanel.CreateWithChild(p);
			
			Assert.AreEqual("1", p.TS.Test_JoinValues());
			
			p.CallRemoveO1.Perform(); //goes below MinCount, thus nothing
			root.StepFrameJS();
			Assert.AreEqual("1", p.TS.Test_JoinValues());
			
			p.CallForceRemoveO1.Perform();
			root.StepFrameJS();
			Assert.AreEqual("", p.TS.Test_JoinValues());
			
			p.TS.Add(p.O2.Sel);
			p.TS.Add(p.O3.Sel);
			p.CallAddO1.Perform();
			root.StepFrameJS();
			Assert.AreEqual("3,1", p.TS.Test_JoinValues()); //since Replace=Oldest by default
			
			p.TS.Clear();
			p.TS.Add(p.O2.Sel);
			p.TS.Add(p.O3.Sel);
			p.CallForceAddO1.Perform();
			root.StepFrameJS();
			Assert.AreEqual("2,3,1", p.TS.Test_JoinValues()); //since Replace=Oldest by default
		}
		
		[Test]
		/* Ensure changes in selectable values from bindings are correctly initialized */
		public void EachSelectable()
		{
			var p = new UX.EachSelectable();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				var one = root.FindNodeByName("one") as Visual;
				Assert.IsFalse(one == null);
				var two = root.FindNodeByName("two") as Visual;
				Assert.IsFalse(two == null);
				var three = root.FindNodeByName("three") as Visual;
				Assert.IsFalse(three == null);
				
				//https://github.com/fusetools/fuselibs/issues/3385
				//this has been switch to a 0-duration animator for now
				Assert.AreEqual(1,TriggerProgress(two.FirstChild<WhileSelected>()));
				Assert.AreEqual(0,TriggerProgress(one.FirstChild<WhileSelected>()));
				Assert.AreEqual(0,TriggerProgress(three.FirstChild<WhileSelected>()));
				Assert.AreEqual("two", p.TS.Value);
				
				p.E.Limit = 0;
				root.StepFrame();
				Assert.AreEqual("two", p.TS.Value);
			}
		}
	}
}
