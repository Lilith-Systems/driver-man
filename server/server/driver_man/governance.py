from typing import Dict, List

class Proposal:
    def __init__(self, proposal_id: str, description: str):
        self.proposal_id = proposal_id
        self.description = description
        self.votes_for = 0.0
        self.votes_against = 0.0
        self.is_active = True

class DemocraticGovernance:
    def __init__(self):
        self.active_proposals: Dict[str, Proposal] = {}

    def create_proposal(self, proposal_id: str, description: str):
        self.active_proposals[proposal_id] = Proposal(proposal_id, description)

    def cast_vote(self, proposal_id: str, driver_reputation: float, support: bool):
        if proposal_id not in self.active_proposals:
            raise ValueError("Proposal not found")
            
        proposal = self.active_proposals[proposal_id]
        if not proposal.is_active:
            raise ValueError("Proposal is closed")
            
        # Reputation-Weighted Voting: influence scales with sustained contribution
        if support:
            proposal.votes_for += driver_reputation
        else:
            proposal.votes_against += driver_reputation

    def resolve_proposal(self, proposal_id: str) -> bool:
        proposal = self.active_proposals[proposal_id]
        proposal.is_active = False
        return proposal.votes_for > proposal.votes_against
