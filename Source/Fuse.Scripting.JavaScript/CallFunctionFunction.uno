using Uno;
using Uno.UX;
using Fuse;
using Fuse.Reactive;

namespace Fuse.Scripting.JavaScript
{
	[UXFunction("call")]
	public class CallFunctionFunction : SimpleVarArgFunction
	{
		IDisposable _currentCall = null;
		IDisposable _invalidFunctionDiagnostic = null;

		protected override void OnNewArguments(Argument[] expressionArgs, IListener listener)
		{
			if (expressionArgs.Length == 0)
			{
				ReportInvalidFunctionDiagnostic(listener);
				return;
			}

			Scripting.Function function;
			if (!TryGetAsFunction(expressionArgs[0].Value, out function))
			{
				ReportInvalidFunctionDiagnostic(listener);
				return;
			}

			DiscardInvalidFunctionDiagnostic();

			var functionArgs = new object[expressionArgs.Length - 1];
			for (var i = 0; i < functionArgs.Length; ++i)
			{
				functionArgs[i] = expressionArgs[i+1].Value;
			}

			var closure = new CallOnJSThreadClosure(this, function, functionArgs, listener);
			_currentCall = closure;
			Fuse.Reactive.JavaScript.Worker.Invoke(closure.Perform);
		}

		static bool TryGetAsFunction(object obj, out Scripting.Function result)
		{
			var func = obj as Scripting.Function;
			if (func != null)
			{
				result = func;
				return true;
			}

			var mirror = obj as Scripting.FunctionMirror;
			if (mirror != null)
			{
				result = mirror.Raw as Scripting.Function;
				return result != null;
			}

			result = null;
			return false;
		}

		void ReportInvalidFunctionDiagnostic(IListener listener)
		{
			DiscardResult(listener);
			DiscardInvalidFunctionDiagnostic();
			_invalidFunctionDiagnostic = Diagnostics.ReportTemporalUserWarning("call(): First argument is not a function.", this);
		}

		void DiscardInvalidFunctionDiagnostic()
		{
			if(_invalidFunctionDiagnostic == null)
				return;
			
			_invalidFunctionDiagnostic.Dispose();
			_invalidFunctionDiagnostic = null;
		}

		void DiscardResult(IListener listener)
		{
			if (_currentCall != null)
				_currentCall.Dispose();
			
			_currentCall = null;
			listener.OnLostData(this);
		}

		internal class CallOnJSThreadClosure : IDisposable
		{
			IExpression _source;
			Scripting.Function _function;
			object[] _args;
			IListener _listener;

			bool _isDisposed;
			object _disposeLock = new object();

			public CallOnJSThreadClosure(IExpression source, Scripting.Function function, object[] args, IListener listener)
			{
				_source = source;
				_function = function;
				_args = args;
				_listener = listener;
			}

			public void Perform(Scripting.Context context)
			{
				lock (_disposeLock)
				{
					if (_isDisposed)
						return;
				}

				for(var i = 0; i < _args.Length; ++i)
				{
					_args[i] = context.Unwrap(_args[i]);
				}

				var result = context.Wrap(_function.Call(context, _args));
				UpdateManager.PostAction(new NotifyListenerOnUIThreadClosure(_source, _listener, result).Perform);
			}

			void IDisposable.Dispose()
			{
				lock (_disposeLock)
				{
					_isDisposed = true;
					_function = null;
					_args = null;
					_listener = null;
				}
			}
		}

		internal class NotifyListenerOnUIThreadClosure
		{
			IExpression _source;
			IListener _listener;
			object _data;

			public NotifyListenerOnUIThreadClosure(IExpression source, IListener listener, object data)
			{
				_source = source;
				_listener = listener;
				_data = data;
			}

			public void Perform()
			{
				_listener.OnNewData(_source, _data);
			}
		}
	}
}
