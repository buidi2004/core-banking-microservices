package com.fintech.notification.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "promotions")
public class Promotion {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "type", nullable = false, length = 50)
    private String type;

    @Column(name = "target_amount")
    private Long targetAmount = 0L;

    @Column(name = "reward_amount")
    private Long rewardAmount = 0L;

    @Column(name = "max_reward_per_user")
    private Long maxRewardPerUser = 0L;

    @Column(name = "total_reward_budget")
    private Long totalRewardBudget = 0L;

    @Column(name = "reward_claimed", nullable = false)
    private Long rewardClaimed = 0L;

    @Column(name = "participant_limit")
    private Integer participantLimit = 0;

    @Column(name = "participants_count", nullable = false)
    private Integer participantsCount = 0;

    @Column(name = "start_date", nullable = false)
    private Instant startDate;

    @Column(name = "end_date", nullable = false)
    private Instant endDate;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "rules_json", columnDefinition = "jsonb")
    private String rulesJson;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Promotion() {
    }

    @PrePersist
    void onCreate() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public boolean isCurrentlyValid() {
        Instant now = Instant.now();
        return active && (startDate == null || !now.isBefore(startDate))
                && (endDate == null || !now.isAfter(endDate));
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public Long getTargetAmount() { return targetAmount; }
    public void setTargetAmount(Long targetAmount) { this.targetAmount = targetAmount; }

    public Long getRewardAmount() { return rewardAmount; }
    public void setRewardAmount(Long rewardAmount) { this.rewardAmount = rewardAmount; }

    public Long getMaxRewardPerUser() { return maxRewardPerUser; }
    public void setMaxRewardPerUser(Long maxRewardPerUser) { this.maxRewardPerUser = maxRewardPerUser; }

    public Long getTotalRewardBudget() { return totalRewardBudget; }
    public void setTotalRewardBudget(Long totalRewardBudget) { this.totalRewardBudget = totalRewardBudget; }

    public Long getRewardClaimed() { return rewardClaimed; }
    public void setRewardClaimed(Long rewardClaimed) { this.rewardClaimed = rewardClaimed; }

    public Integer getParticipantLimit() { return participantLimit; }
    public void setParticipantLimit(Integer participantLimit) { this.participantLimit = participantLimit; }

    public Integer getParticipantsCount() { return participantsCount; }
    public void setParticipantsCount(Integer participantsCount) { this.participantsCount = participantsCount; }

    public Instant getStartDate() { return startDate; }
    public void setStartDate(Instant startDate) { this.startDate = startDate; }

    public Instant getEndDate() { return endDate; }
    public void setEndDate(Instant endDate) { this.endDate = endDate; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getRulesJson() { return rulesJson; }
    public void setRulesJson(String rulesJson) { this.rulesJson = rulesJson; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
