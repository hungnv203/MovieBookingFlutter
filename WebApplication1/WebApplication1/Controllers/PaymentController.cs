using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Net.payOS.Types;
using Net.payOS;
using WebApplication1.Types;
using Google.Cloud.Firestore;
using Net.payOS.Errors;
using Microsoft.AspNetCore.Http.HttpResults;

namespace WebApplication1.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class PaymentController : ControllerBase
    {
        private readonly PayOS _payOS;

        public PaymentController(PayOS payOS)
        {
            _payOS = payOS;
        }

        [HttpPost("payos_transfer_handler")]
        public IActionResult PayOSTransferHandler([FromBody] WebhookType body)
        {
            try
            {
                WebhookData data = _payOS.verifyPaymentWebhookData(body);

                // Xử lý sau trong background
                Task.Run(async () =>
                {
                    string orderId = data.description;

                    var firestore = FirestoreDb.Create("flutter-1df87");
                    var document = firestore.Collection("bookings").Document(orderId);
                    var snapshot = await document.GetSnapshotAsync();

                    if (snapshot.Exists)
                    {
                        await document.UpdateAsync(new Dictionary<string, object>
                {
                    { "paymentStatus", "Đã thanh toán" }
                });
                    }
                });

                // Trả về OK ngay lập tức
                return Ok(new Response(0, "Received", null));
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                return BadRequest();
            }
        }


        [HttpPost("create")]
        public async Task<IActionResult> CreatePaymentLink(CreatePaymentLinkRequest body)
        {
            try
            {
                int orderCode = int.Parse(DateTimeOffset.Now.ToString("ffffff"));
                ItemData item = new ItemData(body.productName, 1, body.price);
                List<ItemData> items = new List<ItemData>();
                items.Add(item);
                PaymentData paymentData = new PaymentData(orderCode, body.price, body.description, items, body.cancelUrl, body.returnUrl);

                CreatePaymentResult createPayment = await _payOS.createPaymentLink(paymentData);

                return Ok(new Response(0, "success", createPayment));
            }
            catch (System.Exception exception)
            {
                Console.WriteLine(exception);
                return Ok(new Response(-1, "fail", null));
            }
        }
        [HttpPost("confirm-webhook")]
        public async Task<IActionResult> ConfirmWebhook(ConfirmWebhook body)
        {
            try
            {
                Console.WriteLine($"Confirming webhook with URL: {body.webhook_url}");

                await _payOS.confirmWebhook(body.webhook_url);

                Console.WriteLine("Webhook confirmed successfully");

                return Ok(new Response(0, "Ok", null));
            }
            catch (Net.payOS.Errors.PayOSError ex)
            {
                Console.WriteLine($"PayOS error occurred: {ex.Message}");
                Console.WriteLine(ex.StackTrace);

                // Xử lý trả về lỗi chi tiết từ PayOS
                return StatusCode(500, new Response(-1, "PayOS error", ex.Message));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"General error: {ex.Message}");
                Console.WriteLine(ex.StackTrace);

                return StatusCode(500, new Response(-1, "Internal Server Error", ex.Message));
            }
        }
        [HttpPut("{orderId}")]
        public async Task<IActionResult> CancelOrder([FromRoute] int orderId)
        {
            try
            {
                PaymentLinkInformation paymentLinkInformation = await _payOS.cancelPaymentLink(orderId);
                return Ok(new Response(0, "Ok", paymentLinkInformation));
            }
            catch (System.Exception exception)
            {

                Console.WriteLine(exception);
                return Ok(new Response(-1, "fail", null));
            }

        }
        [HttpGet("{orderId}")]
        public async Task<IActionResult> GetOrder([FromRoute] int orderId)
        {
            try
            {
                PaymentLinkInformation paymentLinkInformation = await _payOS.getPaymentLinkInformation(orderId);
                return Ok(new Response(0, "Ok", paymentLinkInformation));
            }
            catch (System.Exception exception)
            {

                Console.WriteLine(exception);
                return Ok(new Response(-1, "fail", null));
            }

        }
        [HttpGet("test-firestore")]
        public async Task<IActionResult> TestFirestoreConnection()
        {
            try
            {
                // Kết nối tới Firestore
                var firestore = FirestoreDb.Create("flutter-1df87");

                // Lấy danh sách document trong collection bookings (giới hạn 1)
                var snapshot = await firestore.Collection("bookings").Limit(1).GetSnapshotAsync();

                if (snapshot.Count == 0)
                {
                    return Ok(new Response(0, "Kết nối thành công, nhưng không có dữ liệu trong 'bookings'", null));
                }

                // Lấy document đầu tiên
                var firstDoc = snapshot.Documents[0];
                var data = firstDoc.ToDictionary();

                return Ok(new Response(0, "Kết nối Firestore thành công", data));
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
                return StatusCode(500, new Response(-1, "Kết nối Firestore thất bại", ex.Message));
            }
        }

    }
}
