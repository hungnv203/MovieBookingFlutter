using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Net.payOS;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", @"C:/Users/vanhu/Downloads/flutter-1df87-bfc2282204fb.json");

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSingleton(provider =>
    new PayOS(
        clientId: "0cb4ff12-64a0-4915-b5d9-2e9b10d42174",
        apiKey: "79452dec-e224-47be-b52e-8dc1a70cd017",
        checksumKey: "768a4bc2a06468b6f6c8b0389ac49bf2d696198d9532f2e9dcea21054845bae7"
    )
);
FirebaseApp.Create(new AppOptions
{
    Credential = GoogleCredential.FromFile("C:/Users/vanhu/Downloads/flutter-1df87-bfc2282204fb.json")
});
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(
        policy =>
        {
            policy.WithOrigins("*").AllowAnyHeader().AllowAnyMethod();
        });
});
var app = builder.Build();
// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseCors();
app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
