﻿namespace WebApplication1.Types
{
    public record CreatePaymentLinkRequest(
    string productName,
    string description,
    int price,
    string returnUrl,
    string cancelUrl
);

}
