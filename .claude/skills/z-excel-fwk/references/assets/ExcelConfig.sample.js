sap.ui.define([], function () {
    "use strict";

    return {
        // 1. Mã định danh của App (Truyền xuống parameter app_id)
        appId: "",

        // 2. ID Template Excel đăng ký trên Node.js (Fallback nếu Backend không trả về)
        excelId: "",

        // 3. Đường dẫn Static Action OData V4 cấu hình trong BDEF
        actionPath: "/{Entity Set} /com.sap.gateway.srvd.{Service Definition} v0001.{Action}(...)",

        // 4. Khóa chính của Business Object (TỰ ĐỘNG KHÔNG CẦN KHAI BÁO)
        // Nếu để trống (""), hệ thống sẽ tự động quét OData Metadata để lấy danh sách khóa (hỗ trợ cả khóa đơn và khóa kép).
        // Chỉ khai báo thủ công nếu muốn ghi đè (Ví dụ: "MaterialId" hoặc ["SalesOrderId", "SalesOrderItemId"])
        idProperty: "",

        // 5. Tham số mở rộng nếu có (Truyền xuống parameter custom_param)
        customParam: ""
    };
});