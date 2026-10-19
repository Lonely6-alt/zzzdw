package com.fenglin.springboottest.common;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

/**
 * 全局异常处理：把异常统一转成前端约定的 { "message": "..." } 格式。
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /** 业务异常：按携带的状态码返回 */
    @ExceptionHandler(BizException.class)
    public ResponseEntity<Map<String, String>> handleBiz(BizException e) {
        return ResponseEntity.status(e.getStatus())
                .body(Map.of("message", e.getMessage()));
    }

    /** 缺少必填请求参数（如验证码接口缺 id）：返回 400 */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, String>> handleMissingParam(MissingServletRequestParameterException e) {
        return ResponseEntity.badRequest()
                .body(Map.of("message", "缺少必填参数：" + e.getParameterName()));
    }

    /** 兜底异常：统一 500，避免把堆栈暴露给前端 */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleOther(Exception e) {
        return ResponseEntity.internalServerError()
                .body(Map.of("message", "服务器内部错误：" + e.getMessage()));
    }
}
