namespace WebApplication1.Types
{
    public record Response
    (
        int code,
        string message,
        object? data
    );
}
