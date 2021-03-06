using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	public abstract class ExpressionBinding: Binding, IContext, IListener
	{
		public IExpression Key { get; private set; }

		[WeakReference]
		NameTable _nameTable;
		public NameTable NameTable { get { return _nameTable; } }


		protected ExpressionBinding(IExpression key, NameTable nameTable)
		{
			Key = key;
			_nameTable = nameTable;
		}

		IDisposable _expressionSub;

		protected internal bool CanWriteBack { get { return _expressionSub is IWriteable; } }
		protected internal void WriteBack(object value) { ((IWriteable)_expressionSub).SetExclusive(value); }

		protected override void OnRooted()
		{
			base.OnRooted();
			_expressionSub = Key.Subscribe(this, this);
		}

		IDisposable IContext.Subscribe(IExpression source, string key, IListener listener)
		{
			return new DataSubscription(source, this, key, listener);
		}

		Node IContext.Node { get { return Parent; } }

		public virtual IDisposable SubscribeResource(IExpression source, string key, IListener listener)
		{
			throw new Exception("The binding type does not support resource subscriptions");
		}

		protected override void OnUnrooted()
		{
			_expressionSub.Dispose();
			_expressionSub = null;
			base.OnUnrooted();
		}

		void IListener.OnNewData(IExpression source, object obj) { NewValue(obj); }

		internal abstract void NewValue(object obj);
	}
}