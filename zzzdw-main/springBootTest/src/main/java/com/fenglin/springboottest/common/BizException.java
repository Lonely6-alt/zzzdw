package com.fenglin.springboottest.common;

import org.springframework.http.HttpStatus;

/**
 * 业务异常：携带 HTTP 状态码，由全局异常处理器统一转成 { "message": "..." } 返回前端。
 */
public class BizException extends RuntimeException {

    private final int status;

    public BizException(int status, String message) {
        super(message);
        this.status = status;
    }

    public BizException(HttpStatus status, String message) {
        super(message);
        this.status = status.value();
    }

    public int getStatus() {
        return status;
    }
}
