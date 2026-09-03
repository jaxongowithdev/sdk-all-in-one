package com.example.all_in_one_sdk;

import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.junit.Test;

public class AllInOneSdkPluginTest {

  @Test
  public void onMethodCall_getPlatformVersion_returnsAndroidVersion() {
    AllInOneSdkPlugin plugin = new AllInOneSdkPlugin();
    MethodCall call = new MethodCall("getPlatformVersion", null);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    plugin.onMethodCall(call, mockResult);

    verify(mockResult)
        .success(
            argThat(
                (Object s) ->
                    s != null && s.toString().startsWith("Android ")));
  }
}
